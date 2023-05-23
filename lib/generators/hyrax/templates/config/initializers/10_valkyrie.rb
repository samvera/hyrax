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
end
