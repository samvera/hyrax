module CurationConcerns
  module Naming
    extend ActiveSupport::Concern

    module ClassMethods
      # Override of ActiveModel::Model name that allows us to use our custom name class
      def model_name
        @_model_name ||= begin
          namespace = parents.detect do |n|
            n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
          end
          CurationConcerns::Name.new(self, namespace)
        end
      end
    end
  end
end
