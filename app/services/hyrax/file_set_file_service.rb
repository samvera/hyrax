# frozen_string_literal: true

module Hyrax
  ##
  # A service for accessing specific Hyrax::FileMetadata objects referenced by a
  # Hyrax::FileSet.
  class FileSetFileService
    ##
    # @!attribute [r] file_set
    #   @return [Hyrax::FileSet]
    attr_reader :file_set

    ##
    # @!attribute [r] query_service
    #   @return [#find_by]
    attr_reader :query_service

    ##
    # @param resource [Hyrax::FileSet]
    def initialize(file_set:, query_service: Hyrax.query_service)
      @query_service = query_service
      @file_set = file_set
    end

    ##
    # Return the Hyrax::FileMetadata which should be considered “original” for
    # indexing and version‐tracking.
    #
    # If +file_set.original_file_id+ is defined, it will be used; otherwise,
    # this requires a custom query. The ultimate fallback, if no
    # pcdm:OriginalFile is associated with the :file_set, is to just use the
    # first file in its :file_ids.
    #
    # @return [Hyrax::FileMetadata]
    def original_file
      if file_set.original_file_id
        # Always just use original_file_id if it is defined.
        query_service.find_by(id: file_set.original_file_id)
      else
        # Cache the fallback to avoid needing to do this query twice.
        @original_file ||= begin
                             query_service.custom_queries.find_original_file(file_set: file_set)
                           rescue Valkyrie::Persistence::ObjectNotFoundError
                             fallback_id = file_set.file_ids.first
                             query_service.find_by(id: fallback_id) if fallback_id
                           end
      end
    end
  end
end
