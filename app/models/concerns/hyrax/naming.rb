# frozen_string_literal: true

require_dependency 'hyrax/name'

module Hyrax
  module Naming
    extend ActiveSupport::Concern

    module ClassMethods
      # Override of ActiveModel::Model name that allows us to use our custom name class
      def model_name(name_class: _hyrax_default_name_class)
        @_model_name ||= begin
          namespace = parents.detect do |n|
            n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
          end
          name_class.new(self, namespace)
        end
      end

      private

      def _hyrax_default_name_class
        Hyrax::Name
      end
    end
  end
end
