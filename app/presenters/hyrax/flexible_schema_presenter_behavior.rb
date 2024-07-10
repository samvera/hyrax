# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaPresenterBehavior
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
    end

    module ClassMethods
      def delegated_properties
        Hyrax::FlexibleSchema.default_properties
      end
    end

    def reload_dynamic_methods
      if Hyrax.config.flexible?
        self.class.delegate(*self.class.delegated_properties, to: :solr_document)
      end
    end
  end
end
