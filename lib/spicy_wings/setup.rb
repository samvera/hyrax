ActiveFedora::Base.include SpicyWings::Valkyrizable

Valkyrie::MetadataAdapter.register(
  SpicyWings::Valkyrie::MetadataAdapter.new, :spicy_wings_adapter
)
Valkyrie.config.metadata_adapter = :spicy_wings_adapter

if ENV['RAILS_ENV'] == 'test'
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter
  )
end

Valkyrie::StorageAdapter.register(
  SpicyWings::Storage::ActiveFedora
    .new(connection: Ldp::Client.new(ActiveFedora.fedora.host), base_path: ActiveFedora.fedora.base_path),
  :active_fedora
)
Valkyrie.config.storage_adapter = :active_fedora

# TODO: Custom query registration is not SpicyWings specific.  These custom_queries need to be registered for other adapters too.
#       A refactor is needed to add the default implementations to hyrax.rb and only handle the spicy_wings specific overrides here.
custom_queries = [Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                  Hyrax::CustomQueries::Navigators::FindFiles,
                  SpicyWings::CustomQueries::FindAccessControl, # override Hyrax::CustomQueries::FindAccessControl
                  SpicyWings::CustomQueries::FindFileMetadata, # override Hyrax::CustomQueries::FindFileMetadata
                  SpicyWings::CustomQueries::FindManyByAlternateIds] # override Hyrax::CustomQueries::FindManyByAlternateIds
custom_queries.each do |query_handler|
  Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
end

SpicyWings::ModelRegistry.register(Hyrax::AccessControl,     Hydra::AccessControl)
SpicyWings::ModelRegistry.register(Hyrax::AdministrativeSet, AdminSet)
SpicyWings::ModelRegistry.register(Hyrax::PcdmCollection,    ::Collection)
SpicyWings::ModelRegistry.register(Hyrax::FileSet,           FileSet)
SpicyWings::ModelRegistry.register(Hyrax::Embargo,           Hydra::AccessControls::Embargo)
SpicyWings::ModelRegistry.register(Hyrax::Lease,             Hydra::AccessControls::Lease)
