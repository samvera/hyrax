# frozen_string_literal: true

module Hyrax
  # Validates every `type: orcid` sub-property value on a compound's persisted
  # rows. A blank value is allowed (required-ness lives in
  # {Hyrax::CompoundEntryValidator}); a non-blank value must match
  # {Hyrax::OrcidValidator::ORCID_REGEXP} in either the bare-iD form
  # (`0000-0000-0000-0000`) or the full `https://orcid.org/` URL form.
  #
  # Adds one error per offending row to `:base`, naming the compound and the
  # offending sub-property — same keying convention {Hyrax::CompoundEntryValidator}
  # uses so work and collection forms render the message cleanly. See
  # documentation/compound_fields.md.
  class OrcidSubpropertyValidator < ActiveModel::Validator
    def validate(record)
      schema = Hyrax::CompoundSchema.for(schema_source(record))
      schema.definitions.each do |name, definition|
        next unless record.respond_to?(name)
        validate_compound(record, name, definition)
      end
    rescue StandardError => e
      Hyrax.logger.debug("OrcidSubpropertyValidator: #{e.message}")
    end

    private

    # The schema declarations live on the underlying resource, not the form
    # wrapper: a Reform form exposes it as `model`. Fall back to the record
    # itself (e.g. a plain ActiveModel object in unit tests).
    def schema_source(record)
      record.respond_to?(:model) ? record.model : record
    end

    def validate_compound(record, name, definition)
      orcid_keys = definition[:subproperties].select { |_key, spec| spec[:type].to_s == 'orcid' }.keys
      return if orcid_keys.empty?

      Array(record.public_send(name)).each do |entry|
        next unless entry.is_a?(Hash)
        orcid_keys.each do |sub_property|
          value = entry[sub_property] || entry[sub_property.to_sym]
          next if value.blank?
          next if Hyrax::OrcidValidator::ORCID_REGEXP.match?(value.to_s)
          record.errors.add(:base, message_for(name, sub_property, value))
        end
      end
    end

    def message_for(name, sub_property, value)
      I18n.t('hyrax.compound_fields.orcid.invalid',
             compound: compound_label(name),
             field: subproperty_label(name, sub_property),
             value: value,
             default: %("#{value}" is not a valid ORCID iD for #{compound_label(name)} > #{subproperty_label(name, sub_property)}.))
    end

    def compound_label(name)
      I18n.t("hyrax.compound_fields.#{name}.label", default: name.to_s.humanize)
    end

    def subproperty_label(compound_name, sub_property)
      I18n.t("hyrax.compound_fields.#{compound_name}.#{sub_property}", default: sub_property.to_s.humanize)
    end
  end
end
