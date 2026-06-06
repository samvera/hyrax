# frozen_string_literal: true
module Hyrax
  module FlexibleFormBehavior
    extend ActiveSupport::Concern

    included do
      property :contexts

      validate :validate_flexible_required_fields
    end

    def validate_flexible_required_fields
      required_fields = singleton_class.schema_definitions.select { |_, opts| opts[:required] }.keys

      required_fields.each do |field|
        # Compound fields carry their own requiredness rules (per-row sub-property
        # checks); Hyrax::CompoundEntryValidator owns them, so skip the generic
        # blank check to avoid a duplicate "can't be blank" error.
        next if compound_field?(field)
        value = send(field)
        errors.add(field, :blank) if value.blank?
      end
    end

    # OVERRIDE disposable 0.6.3 to make schema dynamic
    def schema
      Hyrax::Forms::ResourceForm::Definition::Each.new(singleton_class.schema_definitions)
    end

    private

    # Whether the field is a compound (declares `subproperties:`), looked up from
    # the resource's compound schema — the flex form definitions don't carry
    # `subproperties`. Memoized per form instance.
    def compound_field?(field)
      return false unless Hyrax.config.respond_to?(:compound_metadata_enabled?) && Hyrax.config.compound_metadata_enabled?
      @compound_field_names ||= Hyrax::CompoundSchema.for(model).compound_names
      @compound_field_names.include?(field.to_sym)
    rescue StandardError
      false
    end

    # OVERRIDE valkyrie 3.0.1 to make schema dynamic
    def field(field_name)
      singleton_class.schema_definitions.fetch(field_name.to_s)
    end

    def _form_field_definitions
      singleton_class.schema_definitions
    end
  end
end
