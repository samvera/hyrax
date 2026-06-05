# frozen_string_literal: true

module Hyrax
  # Validates every compound (hierarchical) metadata attribute on a form,
  # blocking save when a required compound has no row or a populated row omits a
  # required sub-field. Adds one error per compound, keyed on the compound name.
  #
  # Record-level (not an EachValidator) because the compound set is schema-driven
  # and not known at form-class-definition time. The per-compound rules live in
  # the reusable {Hyrax::CompoundEntryValidation}. See
  # documentation/forms/compound_fields.md.
  class CompoundEntryValidator < ActiveModel::Validator
    def validate(record)
      return unless Hyrax.config.compound_metadata_enabled?

      schema = Hyrax::CompoundSchema.for(schema_source(record))
      schema.definitions.each do |name, definition|
        next unless record.respond_to?(name)
        validate_compound(record, name, definition)
      end
    rescue StandardError => e
      Hyrax.logger.debug("CompoundEntryValidator: #{e.message}")
    end

    private

    # The schema declarations live on the underlying resource, not the form
    # wrapper: a Reform form exposes it as `model`. Fall back to the record
    # itself (e.g. a plain ActiveModel object in unit tests).
    def schema_source(record)
      record.respond_to?(:model) ? record.model : record
    end

    def validate_compound(record, name, definition)
      entries = Array(record.public_send(name))
      Hyrax::CompoundEntryValidation.new(definition, entries).violations.each do |violation|
        # Attach to :base, not the attribute, because the work and collection
        # forms render errors differently (raw messages vs. full_messages):
        # keying on the attribute would either double the field name
        # ("Participants Participants ...") or print the raw key
        # ("participants ..."). A :base
        # error renders verbatim everywhere, and the message names the compound.
        record.errors.add(:base, message_for(name, violation))
      end
    end

    # The message names the compound itself (it is attached to :base, so no
    # attribute-name prefix is added by the view).
    def message_for(name, violation)
      I18n.t("hyrax.compound_fields.errors.#{violation[:type]}",
             compound: compound_label(name),
             fields: subfield_labels(name, violation[:missing]))
    end

    def compound_label(name)
      I18n.t("hyrax.compound_fields.#{name}.label", default: name.to_s.humanize)
    end

    def subfield_labels(name, keys)
      Array(keys).map do |key|
        I18n.t("hyrax.compound_fields.#{name}.#{key}", default: key.to_s.humanize)
      end.join(', ')
    end
  end
end
