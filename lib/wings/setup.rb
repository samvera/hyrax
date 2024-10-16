# frozen_string_literal: true

ActiveFedora::Base.include Wings::Valkyrizable
ActiveFedora::File.include Wings::Valkyrizable
Hydra::AccessControl.include Wings::Valkyrizable

module ActiveTriples
  class NodeConfig
    ##
    # all ActiveTriples nodes are multiple
    #
    # this is a commonly used method on ActiveFedora's node configurations
    # adding the method here gives us a more consistent interface from
    # `ActiveFedora::Base.properties`.
    def multiple?
      true
    end
  end
end

module ActiveFedora
  def self.model_mapper
    ActiveFedora::DefaultModelMapper.new(classifier_class: Wings::ActiveFedoraClassifier)
  end

  class Base
    def self.supports_property?(property)
      property == :permissions ||
        property.to_s.end_with?('_attributes') ||
        properties.key?(property.to_s) ||
        reflections.key?(property.to_sym)
    end
  end

  class File
    alias eql? ==

    def self.supports_property?(property)
      return true if ['pcdm_use'].include?(property.to_s)
      properties.key?(property.to_s)
    end

    def self.properties
      metadata.properties
    end

    def self.default_sort_params
      ["system_create_dtsi asc"]
    end

    def pcdm_use
      metadata.type
    end

    def pcdm_use=(value)
      metadata.type = value
    end
  end

  module WithMetadata
    class MetadataNode
      ##
      # @note fcrepo rejects `:file_hash` updates. the attribute is managed by
      #   the data store. always drop it from changed attributes.
      def changed_attributes
        super.except(:file_hash)
      end

      def pcdm_use
        type
      end

      def pcdm_use=(value)
        self.type = value
      end
    end
  end

  module Associations
    class ContainerProxy
      delegate :build_or_set, to: :@association
    end

    class ContainsAssociation
      def build_or_set(attributes, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| build_or_set(attr, &block) }
        else
          add_to_target(reflection.build_association(attributes)) do |record|
            yield(record) if block_given?
          end
        end
      end
    end
  end
end

Valkyrie::MetadataAdapter.register(
  Wings::Valkyrie::MetadataAdapter.new, :wings_adapter
)
Valkyrie.config.metadata_adapter = :wings_adapter unless Hyrax.config.disable_wings

Valkyrie::StorageAdapter.register(
  Wings::Valkyrie::Storage.new, :active_fedora
)
Valkyrie.config.storage_adapter = :active_fedora unless Hyrax.config.disable_wings

# TODO: Custom query registration is not Wings specific.  These custom_queries need to be registered for other adapters too.
#       A refactor is needed to add the default implementations to hyrax.rb and only handle the wings specific overrides here.
custom_queries = [Hyrax::CustomQueries::Navigators::CollectionMembers,
                  Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator, # deprecated; use ChildFileSetsNavigator
                  Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                  Hyrax::CustomQueries::Navigators::ParentWorkNavigator,
                  Hyrax::CustomQueries::Navigators::FindFiles,
                  Wings::CustomQueries::FindAccessControl, # override Hyrax::CustomQueries::FindAccessControl
                  Wings::CustomQueries::FindCollectionsByType,
                  Wings::CustomQueries::FindFileMetadata, # override Hyrax::CustomQueries::FindFileMetadata
                  Wings::CustomQueries::FindIdsByModel,
                  Wings::CustomQueries::FindManyByAlternateIds,
                  Hyrax::CustomQueries::FindModelsByAccess,
                  Hyrax::CustomQueries::FindCountBy,
                  Hyrax::CustomQueries::FindByDateRange] # override Hyrax::CustomQueries::FindManyByAlternateIds
custom_queries.each do |query_handler|
  Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
end

Valkyrie.config.resource_class_resolver = lambda do |resource_klass_name|
  return resource_klass_name.constantize unless defined?(Wings)
  klass_name = resource_klass_name.gsub(/Resource$/, '')
  # Second one should throw a name error because we do not know what you want if
  # it isn't one of these two options
  klass = klass_name.safe_constantize || resource_klass_name.constantize
  Wings::ModelRegistry.reverse_lookup(klass) || klass
end

Wings::ModelRegistry.register(Hyrax::AccessControl, Hydra::AccessControl)
Wings::ModelRegistry.register(Hyrax.config.admin_set_class_for_wings, AdminSet)
Wings::ModelRegistry.register(Hyrax.config.collection_class_for_wings, ::Collection)
Wings::ModelRegistry.register(Hyrax::FileSet,           FileSet)
Wings::ModelRegistry.register(Hyrax::Embargo,           Hydra::AccessControls::Embargo)
Wings::ModelRegistry.register(Hyrax::Lease,             Hydra::AccessControls::Lease)
Wings::ModelRegistry.register(Hyrax::FileMetadata,      Hydra::PCDM::File)
