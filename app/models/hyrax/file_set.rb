# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `FileSet` domain objects in the Hydra Works model.
  #
  # @see https://wiki.duraspace.org/display/samvera/Hydra%3A%3AWorks+Shared+Modeling
  class FileSet < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :file_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID) # id for FileMetadata resources
    attribute :original_file_id, Valkyrie::Types::ID # id for FileMetadata resource
    attribute :thumbnail_id, Valkyrie::Types::ID # id for FileMetadata resource
    attribute :extracted_text_id, Valkyrie::Types::ID # id for FileMetadata resource

    ##
    # @return [Boolean] true
    def pcdm_object?
      true
    end

    ##
    # @return [Boolean] true
    def file_set?
      true
    end

    def original_file
      Hyrax.query_service.custom_queries.find_file_metadata_by(id: original_file_id)
    end

    def extracted_text
      Hyrax.query_service.custom_queries.find_file_metadata_by(id: extracted_text_id)
    end

    def thumbnail
      Hyrax.query_service.custom_queries.find_file_metadata_by(id: thumbnail_id)
    end
  end
end
