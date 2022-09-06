# frozen_string_literal: true
module Hyrax
  module Forms
    class BatchUploadForm < Hyrax::Forms::WorkForm
      self.model_class = BatchUploadItem

      self.terms -= [:title, :resource_type]

      attr_accessor :payload_concern # a Class name: what is form creating a batch of?

      # The WorkForm delegates `#depositor` to `:model`, but `:model` in the
      # BatchUpload context is a blank work with a `nil` depositor
      # value. This causes the "Sharing With" widget to display the Depositor as
      # "()". We should be able to reliably pull back the depositor of the new
      # batch of works by asking the form's Ability what its `current_user` is.
      def depositor
        current_ability.current_user
      end

      # On the batch upload, title is set per-file.
      def primary_terms
        super - [:title]
      end

      # # On the batch upload, title is set per-file.
      # def secondary_terms
      #   super - [:title]
      # end

      # Override of ActiveModel::Model name that allows us to use our custom name class
      def self.model_name
        @_model_name ||= begin
          namespace = module_parents.detect do |n|
            n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
          end
          Name.new(model_class, namespace)
        end
      end

      def model_name
        self.class.model_name
      end

      # This is required for routing to the BatchUploadController
      def to_model
        self
      end

      # A model name that provides correct routes for the BatchUploadController
      # without changing the param key.
      #
      # Example:
      #   name = Name.new(GenericWork)
      #   name.param_key
      #   # => 'generic_work'
      #   name.route_key
      #   # => 'batch_uploads'
      #
      class Name < ActiveModel::Name
        def initialize(klass, namespace = nil, name = nil)
          super
          @route_key          = "batch_uploads"
          @singular_route_key = ActiveSupport::Inflector.singularize(@route_key)
          @route_key << "_index" if @plural == @singular
        end
      end
    end
  end
end
