# frozen_string_literal: true
module Hyrax
  module CustomQueries
    module Navigators
      ##
      # @example
      #   Hyrax.custom_queries.find_files(file_set: file_set_resource)
      #   Hyrax.custom_queries.find_original_file(file_set: file_set_resource)
      #   Hyrax.custom_queries.find_extracted_text(file_set: file_set_resource)
      #   Hyrax.custom_queries.find_thumbnail(file_set: file_set_resource)
      #
      # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
      # @since 3.0.0
      class FindFiles
        def self.queries
          [:find_files,
           :find_original_file,
           :find_extracted_text,
           :find_thumbnail]
        end

        def initialize(query_service:)
          @query_service = query_service
        end

        attr_reader :query_service
        delegate :resource_factory, to: :query_service

        # Find file ids of a given file set resource, and map to file metadata resources
        # @param file_set [Hyrax::FileSet]
        # @return [Array<Hyrax::FileMetadata>]
        def find_files(file_set:)
          if file_set.respond_to?(:file_ids)
            return [] if file_set.file_ids.blank?
            query_service.custom_queries.find_many_file_metadata_by_ids(ids: file_set.file_ids)
          else
            raise ::Valkyrie::Persistence::ObjectNotFoundError,
                  "#{file_set.internal_resource} is not a `Hydra::FileSet` implementer"
          end
        end

        # Find original file id of a given file set resource, and map to file metadata resource
        # @param file_set [Hyrax::FileSet]
        # @return [Hyrax::FileMetadata]
        def find_original_file(file_set:)
          find_exactly_one_file_by_use(
            file_set: file_set,
            use: Hyrax::FileMetadata::Use::ORIGINAL_FILE
          )
        end

        # Find extracted text id of a given file set resource, and map to file metadata resource
        # @param file_set [Hyrax::FileSet]
        # @return [Hyrax::FileMetadata]
        def find_extracted_text(file_set:)
          find_exactly_one_file_by_use(
            file_set: file_set,
            use: Hyrax::FileMetadata::Use::EXTRACTED_TEXT
          )
        end

        # Find thumbnail id of a given file set resource, and map to file metadata resource
        # @param file_set [Hyrax::FileSet]
        # @return [Hyrax::FileMetadata]
        def find_thumbnail(file_set:)
          find_exactly_one_file_by_use(
            file_set: file_set,
            use: Hyrax::FileMetadata::Use::THUMBNAIL_IMAGE
          )
        end

        private

        ##
        # @api private
        #
        # @return [Hyrax::FileMetadata]
        # @raise [Valkyrie::Persistence::ObjectNotFoundError]
        def find_exactly_one_file_by_use(file_set:, use:)
          files =
            query_service.custom_queries.find_many_file_metadata_by_use(resource: file_set, use: use)

          files.first || raise(Valkyrie::Persistence::ObjectNotFoundError, "FileSet #{file_set.id}'s #{use.fragment} is missing.")
        end
      end
    end
  end
end
