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
      if Hyrax.config.flexible?
        Hyrax::Forms::ResourceForm::Definition::Each.new(singleton_class.schema_definitions)
      else
        super
      end
    end

    private

    # OVERRIDE valkyrie 3.0.1 to make schema dynamic
    def field(field_name)
      if Hyrax.config.flexible?
        singleton_class.schema_definitions.fetch(field_name.to_s)
      else
        super
      end
    end

    def _form_field_definitions
      if Hyrax.config.flexible?
        singleton_class.schema_definitions
      else
        self.class.definitions
      end
    end
  end
end
