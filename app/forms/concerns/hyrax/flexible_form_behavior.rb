# frozen_string_literal: true
module Hyrax
  module FlexibleFormBehavior
    extend ActiveSupport::Concern

    included do
      include Hyrax::BasedNearFieldBehavior
      property :contexts
    end

    # OVERRIDE disposable 0.6.3 to make schema dynamic
    def schema
      Hyrax::Forms::ResourceForm::Definition::Each.new(_form_field_definitions)
    end

    private

    # OVERRIDE valkyrie 3.0.1 to make schema dynamic
    def field(field_name)
      _form_field_definitions.fetch(field_name.to_s)
    rescue KeyError
      Rails.logger.warn("Field '#{field_name}' not found in dynamic schema for #{model.class.name}")
      nil
    end

    def _form_field_definitions
      @_dynamic_form_field_definitions ||= Hyrax::FlexibleSchema.definitions_for(class_name: model.class.name)
    end
  end
end
