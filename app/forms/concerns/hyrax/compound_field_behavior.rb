# frozen_string_literal: true

module Hyrax
  ##
  # Generic, schema-driven form handling for compound metadata fields (see
  # {Hyrax::CompoundSchema}). The generic equivalent of the hand-written
  # {Hyrax::RedirectsFieldBehavior}: it discovers every compound on the form's
  # model and wires each one's virtual `<name>_attributes` property and
  # populator from the schema, in both flex modes.
  module CompoundFieldBehavior
    include Hyrax::CompoundRowPlumbing

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
    # see documentation/field_behaviors.md).
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
    # sub-property keys only, dropping `_destroy` and all-blank rows. A
    # `multiple: true` member with several selected values fans its row out into
    # one entry per value (see {#expand_multiple_members}).
    def compound_attributes_populator(fragment:, as:, **_options)
      name = as.to_s.delete_suffix('_attributes')
      return unless respond_to?(name)

      definition = Hyrax::CompoundSchema.for(model).definition_for(name)
      allowed = (definition || {}).fetch(:subproperties, {}).keys
      multiple_keys = multiple_subproperty_keys(definition)
      public_send(:"#{name}=", build_compound_rows(fragment, allowed, multiple_keys))
    end

    def build_compound_rows(fragment, allowed_keys, multiple_keys = [])
      fragment_pairs(fragment)
        .sort_by { |key, _row| key.to_i }
        .flat_map { |_key, row| compound_row_from(row, allowed_keys, multiple_keys) }
        .compact
    end

    # The sub-property keys declared `form: { multiple: true }` for this
    # compound (empty when the definition is unavailable).
    def multiple_subproperty_keys(definition)
      return [] unless definition.is_a?(Hash)
      definition.fetch(:subproperties, {}).select { |_k, spec| spec[:multiple] }.keys
    end

    # Returns nil for a row marked for destruction or whose declared
    # sub-properties are all blank; otherwise an array of one or more persisted
    # entry hashes — several when a `multiple` member carries multiple values.
    def compound_row_from(row, allowed_keys, multiple_keys = [])
      row = row_hash(row)
      return nil if %w[true 1].include?(row['_destroy'].to_s)

      entry = allowed_keys.index_with { |key| normalize_row_value(row[key], multiple_keys.include?(key)) }
      return nil if entry.values.all?(&:blank?)

      expand_multiple_members(entry, multiple_keys)
    end

    # A `multiple` member is coerced to a compacted array of stripped, non-blank
    # values; any other member keeps its scalar (stripped if a string).
    def normalize_row_value(value, multiple)
      return Array(value).map { |v| v.is_a?(String) ? v.strip : v }.reject(&:blank?) if multiple

      value.is_a?(String) ? value.strip : value
    end

    # Fan `multiple` members out so each stored entry holds one scalar value per
    # such member. With a single multiple member (the common case) this yields
    # one entry per selected value; with several it yields their cartesian
    # product. A multiple member with no values collapses to a single nil, so a
    # row whose only content is its other members is still stored once.
    def expand_multiple_members(entry, multiple_keys)
      present = multiple_keys.select { |key| entry[key].is_a?(Array) && entry[key].any? }
      return [entry.transform_values { |v| v.is_a?(Array) ? nil : v }] if present.empty?

      value_lists = present.map { |key| entry[key] }
      value_lists.first.product(*value_lists[1..]).map do |combo|
        entry.merge(present.zip(combo).to_h)
      end
    end
  end
end
