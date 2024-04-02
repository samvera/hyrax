# frozen_string_literal: true

module Hyrax
  ##
  # A service for accessing {Hyrax::FileMetadata} resources by their status
  # within a {Hyrax::FileSet}. For example, this is the home for the abstraction
  # of a "Primary" file for the FileSet, used for versioning and as the default
  # source for the FileSet label, etc...
  #
  # If you're looking for {Hyrax::FileMetadata} by PCDM Use, use the custom
  # queries (e.g. +Hyrax.custom_queries.find_original_file+).
  #
  # @note housing the "primary" file abstraction here allows us to begin
  #   separating from the idea that the `pcdmuse:OriginalFile` is special
  #   in Hyrax in a hard coded way.
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
    # Return the {Hyrax::FileMetadata} which should be considered “primary” for
    # indexing and version‐tracking.
    #
    # @return [Hyrax::FileMetadata]
    def self.primary_file_for(file_set:, query_service: Hyrax.query_service)
      new(file_set: file_set, query_service: query_service).primary_file
    end

    ##
    # Return the {Hyrax::FileMetadata} which should be considered “primary” for
    # indexing and version‐tracking.
    #
    # If +file_set.original_file_id+ is defined, it will be used; otherwise,
    # this requires a custom query. The ultimate fallback, if no
    # pcdm:OriginalFile is associated with the :file_set, is to just use the
    # first file in its :file_ids.
    #
    # @return [Hyrax::FileMetadata]
    def primary_file
      if file_set.original_file_id
        # Always just use original_file_id if it is defined.
        #
        # NOTE: This needs to use :find_file_metadata_by, not :find_by, because
        # at time of writing the latter does not work in Wings.
        query_service.custom_queries.find_file_metadata_by(id: file_set.original_file_id)
      else
        # Cache the fallback to avoid needing to do this query twice.
        #
        # See NOTE above regarding use of :find_file_metadata_by.
        @primary_file ||= begin
                            query_service.custom_queries.find_original_file(file_set: file_set)
                          rescue Valkyrie::Persistence::ObjectNotFoundError
                            fallback_id = file_set.file_ids.first
                            query_service.custom_queries.find_file_metadata_by(id: fallback_id) if fallback_id
                          end
      end
    end
    alias original_file primary_file
    deprecation_deprecate :original_file
  end
end
