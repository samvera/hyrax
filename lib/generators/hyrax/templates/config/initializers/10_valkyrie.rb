# frozen_string_literal: true

# Uncomment or set HYRAX_SKIP_WINGS=true in ENV to run without Wings ActiveFedora compatiblility.
# Hyrax.config do |config|
#   config.disable_wings = true
# end

if Hyrax.config.disable_wings
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Postgres::MetadataAdapter.new,
    :hyrax_metadata_adapter
  )
  Valkyrie.config.metadata_adapter = :hyrax_metadata_adapter

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Rails.root.join("storage", "files"),
                                file_mover: FileUtils.method(:cp)),
    :disk
  )
  Valkyrie.config.storage_adapter  = :disk

  Valkyrie.config.indexing_adapter = :solr_index
  Hyrax.config.index_adapter = :solr_index

  # TODO: Refactor this and custom query registration lib/wings/setup.rb
  custom_queries = [Hyrax::CustomQueries::Navigators::CollectionMembers,
                    Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
                    Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator,
                    Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator,
                    Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator, # deprecated; use ChildFileSetsNavigator
                    Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                    Hyrax::CustomQueries::Navigators::ParentWorkNavigator,
                    Hyrax::CustomQueries::Navigators::FindFiles,
                    Hyrax::CustomQueries::FindAccessControl, # override Hyrax::CustomQueries::FindAccessControl
                    Hyrax::CustomQueries::FindCollectionsByType,
                    Hyrax::CustomQueries::FindFileMetadata, # override Hyrax::CustomQueries::FindFileMetadata
                    Hyrax::CustomQueries::FindIdsByModel,
                    Hyrax::CustomQueries::FindManyByAlternateIds] # override Hyrax::CustomQueries::FindManyByAlternateIds
  custom_queries.each do |query_handler|
    Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
  end
end
