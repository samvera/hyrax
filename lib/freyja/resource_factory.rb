# frozen_string_literal: true

module Freyja
  # Provides access to generic methods for converting to/from
  # {Valkyrie::Resource} and {Valkyrie::Persistence::Postgres::ORM::Resource}.
  class ResourceFactory < Valkyrie::Persistence::Postgres::ResourceFactory
    # @param object [Valkyrie::Persistence::Postgres::ORM::Resource] AR
    #   record to be converted.
    # @return [Valkyrie::Resource] Model representation of the AR record.
    def to_resource(object:)
      resource = ::Valkyrie::Persistence::Postgres::ORMConverter.new(object, resource_factory: self).convert!

      if resource.respond_to?(:file_ids)
        files = Hyrax.custom_queries.find_many_file_metadata_by_ids(ids: resource.file_ids)
        files.each do |file|
          next unless file.file_identifier.to_s.match(/^fedora:/)

          tempfile = Tempfile.new
          tempfile.binmode
          tempfile.write(URI.open(file.file_identifier.to_s.gsub("fedora:", "http:")).read)

          valkyrie_file = Hyrax.storage_adapter.upload(resource: resource, file: tempfile, original_filename: file.original_filename)
          file.file_identifier = valkyrie_file.id

          Hyrax.persister.save(resource: file)
        end
      end

      super
    end
  end
end
