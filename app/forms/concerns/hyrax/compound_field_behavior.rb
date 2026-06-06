# frozen_string_literal: true

module Hyrax
  ##
  # Generic, schema-driven form handling for compound metadata fields (see
  # {Hyrax::CompoundSchema}). The generic equivalent of the hand-written
  # {Hyrax::RedirectsFieldBehavior}: it discovers every compound on the form's
  # model and wires each one's virtual `<name>_attributes` property and
  # populator from the schema, in both flex modes.
  module CompoundFieldBehavior
    # Register the virtual `<name>_attributes` populator properties on the
    # singleton class for every compound on the resource. Must run before Reform
    # builds the deserialization schema; the flexible-mode init path calls this,
    # while non-flexible mode wires the same properties at class load via
    # {Hyrax::FormFields}.
    #
    # @param [Valkyrie::Resource] resource the form's resource (the form's own
    #   `model` may not be set yet when this runs).
    def register_compound_fields!(resource)
      Hyrax::CompoundSchema.for(resource).compound_names.each do |name|
        next if singleton_class.method_defined?(:"#{name}_attributes=")

        singleton_class.property :"#{name}_attributes",
                                 virtual: true,
                                 populator: :compound_attributes_populator
      end
    rescue StandardError => e
      Hyrax.logger.debug("CompoundFieldBehavior: register failed for #{self.class}: #{e.message}")
    end

    # Strip each compound's renamed bare key so the `<name>_attributes`
    # populator is the single write entry point (the Field Behavior contract;
    # see documentation/forms/field_behaviors.md).
    def deserialize!(params)
      result = super
      return result unless result.respond_to?(:delete)

      compound_field_names.each do |name|
        result.delete(name.to_s)
        result.delete(name.to_sym)
      end
      result
    end

    private

    def compound_field_names
      return [] unless respond_to?(:model) && model
      Hyrax::CompoundSchema.for(model).compound_names
    rescue StandardError => e
      Hyrax.logger.debug("CompoundFieldBehavior: could not read compounds for #{self.class}: #{e.message}")
      []
    end

    # One populator serves every compound (Reform passes the property name as
    # `as:`). Builds the replacement array of plain hashes — declared
    # sub-property keys only, dropping `_destroy` and all-blank rows.
    def compound_attributes_populator(fragment:, as:, **_options)
      name = as.to_s.delete_suffix('_attributes')
      return unless respond_to?(name)

      allowed = Hyrax::CompoundSchema.for(model).subproperty_keys(name)
      public_send(:"#{name}=", build_compound_rows(fragment, allowed))
    end

    def build_compound_rows(fragment, allowed_keys)
      compound_fragment_pairs(fragment)
        .sort_by { |key, _row| key.to_i }
        .map { |_key, row| compound_row_from(row, allowed_keys) }
        .compact
    end

    def compound_fragment_pairs(fragment)
      return {} if fragment.nil?
      fragment.respond_to?(:to_unsafe_h) ? fragment.to_unsafe_h : fragment.to_h
    end

    # Returns nil for a row marked for destruction or whose declared sub-properties
    # are all blank, otherwise the persisted hash for that row.
    def compound_row_from(row, allowed_keys)
      row = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
      return nil if %w[true 1].include?(row['_destroy'].to_s)

      entry = allowed_keys.each_with_object({}) do |key, memo|
        value = row[key]
        memo[key] = value.is_a?(String) ? value.strip : value
      end
      return nil if entry.values.all?(&:blank?)
      entry
    end
  end
end
