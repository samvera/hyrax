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

      def reload_dynamic_methods
        if Hyrax.config.flexible?
          reload_classes
          Hyrax::WorkShowPresenter.new(nil, nil).define_dynamic_methods
        end
      end

      def reload_classes
        ActiveSupport::Dependencies.clear
        Rails.application.eager_load!
      end
    end
  end
end
