# frozen_string_literal: true
require 'faraday/multipart'

# require "shrine/storage/s3"
# require "valkyrie/storage/shrine"
# require "valkyrie/shrine/checksum/s3"

# database = ENV.fetch("METADATA_DB_NAME", "nurax_pg_metadata")
# Rails.logger.info "Establishing connection to postgresql on: " \
#                   "#{ENV["DB_HOST"]}:#{ENV["DB_PORT"]}.\n" \
#                   "Using database: #{database}."
# connection = Sequel.connect(
#   user: ENV["DB_USERNAME"],
#   password: ENV["DB_PASSWORD"],
#   host: ENV["DB_HOST"],
#   port: ENV["DB_PORT"],
#   database: database,
#   max_connections: ENV.fetch("DB_POOL", 5),
#   pool_timeout: ENV.fetch("DB_TIMEOUT", 5000),
#   adapter: :postgres
# )
#
# Valkyrie::MetadataAdapter
#   .register(Valkyrie::Sequel::MetadataAdapter.new(connection: connection),
#             :nurax_pg_metadata_adapter)
Valkyrie::MetadataAdapter.register(
  Valkyrie::Persistence::Postgres::MetadataAdapter.new,
  :pg_metadata
)

# Fedora metadata adapter
# Valkyrie::MetadataAdapter.register(
#   Valkyrie::Persistence::Fedora::MetadataAdapter.new(
#     connection: ::Ldp::Client.new(Hyrax.config.fedora_connection_builder.call(
#       ENV.fetch('FCREPO_URL') { "http://localhost:8080/fcrepo/rest" }
#     )),
#     base_path: Rails.env,
#     schema: Valkyrie::Persistence::Fedora::PermissiveSchema.new(Hyrax::SimpleSchemaLoader.new.permissive_schema_for_valkrie_adapter),
#     fedora_version: 6
#   ), :fedora_metadata
# )

Valkyrie.config.metadata_adapter = ENV.fetch('VALKYRIE_METADATA_ADAPTER') { :pg_metadata }.to_sym

# shrine_s3_options = {
#   bucket: ENV.fetch("REPOSITORY_S3_BUCKET") { "nurax_pg#{Rails.env}" },
#   region: ENV.fetch("REPOSITORY_S3_REGION", "us-east-1"),
#   access_key_id: (ENV["REPOSITORY_S3_ACCESS_KEY"] || ENV["MINIO_ACCESS_KEY"]),
#   secret_access_key: (ENV["REPOSITORY_S3_SECRET_KEY"] || ENV["MINIO_SECRET_KEY"])
# }
#
# if ENV["MINIO_ENDPOINT"].present?
#   shrine_s3_options[:endpoint] = "http://#{ENV["MINIO_ENDPOINT"]}:#{ENV.fetch("MINIO_PORT", 9000)}"
#   shrine_s3_options[:force_path_style] = true
# end
#
# Valkyrie::StorageAdapter.register(
#   Valkyrie::Storage::Shrine.new(Shrine::Storage::S3.new(**shrine_s3_options)),
#   :repository_s3
# )
#
# Valkyrie.config.storage_adapter = :repository_s3

# Fedora storage adapter
# Valkyrie::StorageAdapter.register(
#   Valkyrie::Storage::Fedora.new(
#     connection: ::Ldp::Client.new(Hyrax.config.fedora_connection_builder.call(
#       ENV.fetch('FCREPO_URL') { "http://localhost:8080/fcrepo/rest" }
#     )),
#     base_path: Rails.env,
#     fedora_version: 6
#   ), :fedora_storage
# )

Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::VersionedDisk.new(base_path: Rails.root.join("storage", "files"),
                                       file_mover: FileUtils.method(:cp)),
  :versioned_disk_storage
)

Valkyrie.config.storage_adapter  = ENV.fetch('VALKYRIE_STORAGE_ADAPTER') { :versioned_disk_storage }.to_sym

Valkyrie.config.indexing_adapter = :solr_index

custom_queries = [Hyrax::CustomQueries::Navigators::CollectionMembers,
                  Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                  Hyrax::CustomQueries::Navigators::ParentWorkNavigator,
                  Hyrax::CustomQueries::Navigators::FindFiles,
                  Hyrax::CustomQueries::FindAccessControl,
                  Hyrax::CustomQueries::FindCollectionsByType,
                  Hyrax::CustomQueries::FindFileMetadata,
                  Hyrax::CustomQueries::FindIdsByModel,
                  Hyrax::CustomQueries::FindManyByAlternateIds,
                  Hyrax::CustomQueries::FindModelsByAccess,
                  Hyrax::CustomQueries::FindCountBy,
                  Hyrax::CustomQueries::FindByDateRange]
custom_queries.each do |handler|
  Hyrax.query_service.custom_queries.register_query_handler(handler)
end
