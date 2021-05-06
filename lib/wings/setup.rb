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
      properties.key?(property.to_s)
    end

    def self.properties
      metadata.properties
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
Valkyrie.config.metadata_adapter = :wings_adapter

Valkyrie::StorageAdapter.register(
  Wings::Valkyrie::Storage.new, :active_fedora
)
Valkyrie.config.storage_adapter = :active_fedora

# TODO: Custom query registration is not Wings specific.  These custom_queries need to be registered for other adapters too.
#       A refactor is needed to add the default implementations to hyrax.rb and only handle the wings specific overrides here.
custom_queries = [Hyrax::CustomQueries::Navigators::CollectionMembers,
                  Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                  Hyrax::CustomQueries::Navigators::FindFiles,
                  Wings::CustomQueries::FindAccessControl, # override Hyrax::CustomQueries::FindAccessControl
                  Wings::CustomQueries::FindCollectionsByType,
                  Wings::CustomQueries::FindFileMetadata, # override Hyrax::CustomQueries::FindFileMetadata
                  Wings::CustomQueries::FindIdsByModel,
                  Wings::CustomQueries::FindManyByAlternateIds] # override Hyrax::CustomQueries::FindManyByAlternateIds
custom_queries.each do |query_handler|
  Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
end

Wings::ModelRegistry.register(Hyrax::AccessControl,     Hydra::AccessControl)
Wings::ModelRegistry.register(Hyrax::AdministrativeSet, AdminSet)
Wings::ModelRegistry.register(Hyrax::PcdmCollection,    ::Collection)
Wings::ModelRegistry.register(Hyrax::FileSet,           FileSet)
Wings::ModelRegistry.register(Hyrax::Embargo,           Hydra::AccessControls::Embargo)
Wings::ModelRegistry.register(Hyrax::Lease,             Hydra::AccessControls::Lease)
Wings::ModelRegistry.register(Hyrax::FileMetadata,      Hydra::PCDM::File)
