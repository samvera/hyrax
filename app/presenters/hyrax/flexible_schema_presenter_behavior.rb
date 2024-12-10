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
  end
end
