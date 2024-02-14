# frozen_string_literal: true
module Hyrax
  module CollectionBehavior
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight
    include Hydra::WithDepositor # for access to apply_depositor_metadata
    include Hyrax::CoreMetadata
    include Hydra::Works::CollectionBehavior
    include Hyrax::Noid
    include Hyrax::HumanReadableType
    include Hyrax::HasRepresentative
    include Hyrax::Permissions

    included do
      validates_with HasOneTitleValidator
      after_destroy :destroy_permission_template

      self.indexer = Hyrax::CollectionIndexer

      ##
      # @!group Class Attributes
      #
      # @!attribute internal_resource
      #   @return [String]
      class_attribute :internal_resource, default: "Collection"

      class_attribute :index_collection_type_gid_as, instance_writer: false
      ##
      self.index_collection_type_gid_as = [:symbol]

      property :collection_type_gid, predicate: ::RDF::Vocab::SCHEMA.additionalType, multiple: false do |index|
        index.as(*index_collection_type_gid_as)
      end

      # validates that collection_type_gid is present
      validates :collection_type_gid, presence: true

      # Need to define here in order to override setter defined by ActiveTriples
      def collection_type_gid=(new_collection_type_gid)
        new_collection_type_gid = new_collection_type_gid&.to_s
        raise "Can't modify collection type of this collection" if
          !Thread.current[:force_collection_type_gid] && # Used by update_collection_type_global_ids rake task
          persisted? && !collection_type_gid_was.nil? && collection_type_gid_was != new_collection_type_gid
        new_collection_type = Hyrax::CollectionType.find_by_gid!(new_collection_type_gid)
        super(new_collection_type_gid)
        @collection_type = new_collection_type
        collection_type_gid
      end
    end

    def collection_type=(new_collection_type)
      self.collection_type_gid = new_collection_type.to_global_id
    end

    # @return [Enumerable<ActiveFedora::Base>] an enumerable over the children of this collection
    def member_objects
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}")
    end

    # Use this query to get the ids of the member objects (since the containment
    # association has been flipped)
    def member_object_ids
      return [] unless id
      member_objects.map(&:id)
    end

    def to_s
      title.present? ? title.join(' | ') : 'No Title'
    end

    module ClassMethods
      # This governs which partial to draw when you render this type of object
      def _to_partial_path # :nodoc:
        @_to_partial_path ||= begin
          element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
          collection = ActiveSupport::Inflector.tableize(name)
          "hyrax/#{collection}/#{element}"
        end
      end
    end

    # @api public
    # Retrieve the permission template for this collection.
    # @return [Hyrax::PermissionTemplate]
    # @raise [ActiveRecord::RecordNotFound]
    def permission_template
      Hyrax::PermissionTemplate.find_by!(source_id: id)
    end

    private

    # Solr field name works use to index member ids
    def member_ids_field
      "member_ids_ssim"
    end

    def destroy_permission_template
      permission_template.destroy
    rescue ActiveRecord::RecordNotFound
      true
    end
  end
end
