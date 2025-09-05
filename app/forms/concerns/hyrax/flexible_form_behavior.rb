# frozen_string_literal: true
module Hyrax
  module FlexibleFormBehavior
    extend ActiveSupport::Concern

    included do
      property :contexts
    end

    # OVERRIDE disposable 0.6.3 to make schema dynamic
    def schema
      Hyrax::Forms::ResourceForm::Definition::Each.new(singleton_class.schema_definitions)
    end

    private

    # OVERRIDE valkyrie 3.0.1 to make schema dynamic
    def field(field_name)
      singleton_class.schema_definitions.fetch(field_name.to_s)
    end

    def _form_field_definitions
      singleton_class.schema_definitions
    end
  end
end
