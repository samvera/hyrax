module Sufia
  class BatchUploadForm < Sufia::Forms::WorkForm
    self.model_class = ::GenericWork
    include HydraEditor::Form::Permissions

    # Override of ActiveModel::Model name that allows us to use our
    # custom name class
    def self.model_name
      @_model_name ||= begin
        namespace = parents.detect do |n|
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
