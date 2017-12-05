module Hyrax
  class BatchUploadChangeSet < WorkChangeSet
    # include HydraEditor::Form::Permissions

    property :creator, multiple: true, required: true
    property :keyword, multiple: true, required: true
    property :rights_statement, required: true

    property :created_at
    property :updated_at
    property :depositor
    property :date_uploaded
    property :date_modified
    property :proxy_depositor
    property :on_behalf_of
    property :label
    property :relative_path
    property :contributor
    property :description
    property :license
    property :publisher
    property :date_created
    property :subject
    property :language
    property :identifier
    property :related_url
    property :source
    property :based_near
    property :arkivo_checksum

    property :admin_set_id
    property :member_of_collection_ids
    property :member_ids
    property :thumbnail_id
    property :representative_id

    attr_accessor :payload_concern # a Class name: what is form creating a batch of?

    def self.work_klass
      ::BatchUploadItem
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
        namespace = parents.detect do |n|
          n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
        end
        Name.new(work_klass, namespace)
      end
    end

    def model_name
      self.class.model_name
    end

    # This is required for routing to the BatchUploadController
    # def to_model
    #   self
    # end

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
    class Name < ::ActiveModel::Name
      def initialize(klass, namespace = nil, name = nil)
        super
        @route_key          = "batch_uploads"
        @singular_route_key = ActiveSupport::Inflector.singularize(@route_key)
        @route_key << "_index" if @plural == @singular
      end
    end
  end
end
