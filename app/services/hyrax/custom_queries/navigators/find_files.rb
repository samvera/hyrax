module Hyrax
  module CustomQueries
    module Navigators
      class FindFiles
        # @example
        #   Hyrax.custom_queries.find_files(file_set: file_set_resource)
        #   Hyrax.custom_queries.find_original_file(file_set: file_set_resource)
        #   Hyrax.custom_queries.find_extracted_text(file_set: file_set_resource)
        #   Hyrax.custom_queries.find_thumbnail(file_set: file_set_resource)

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
            return [] unless file_set.file_ids.present?
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
          if file_set.respond_to?(:original_file_id)
            raise ::Valkyrie::Persistence::ObjectNotFoundError, "File set's original file is blank" if file_set.original_file_id.blank?
            query_service.custom_queries.find_file_metadata_by(id: file_set.original_file_id)
          else
            raise ::Valkyrie::Persistence::ObjectNotFoundError,
                  "#{file_set.internal_resource} is not a `Hydra::FileSet` implementer"
          end
        end

        # Find extracted text id of a given file set resource, and map to file metadata resource
        # @param file_set [Hyrax::FileSet]
        # @return [Hyrax::FileMetadata]
        def find_extracted_text(file_set:)
          if file_set.respond_to?(:extracted_text_id)
            raise ::Valkyrie::Persistence::ObjectNotFoundError, "File set's extracted text is blank" if file_set.extracted_text_id.blank?
            query_service.custom_queries.find_file_metadata_by(id: file_set.extracted_text_id)
          else
            raise ::Valkyrie::Persistence::ObjectNotFoundError,
                  "#{file_set.internal_resource} is not a `Hydra::FileSet` implementer"
          end
        end

        # Find thumbnail id of a given file set resource, and map to file metadata resource
        # @param file_set [Hyrax::FileSet]
        # @return [Hyrax::FileMetadata]
        def find_thumbnail(file_set:)
          if file_set.respond_to?(:thumbnail_id)
            raise ::Valkyrie::Persistence::ObjectNotFoundError, "File set's thumbnail is blank" if file_set.thumbnail_id.blank?
            query_service.custom_queries.find_file_metadata_by(id: file_set.thumbnail_id)
          else
            raise ::Valkyrie::Persistence::ObjectNotFoundError,
                  "#{file_set.internal_resource} is not a `Hydra::FileSet` implementer"
          end
        end
      end
    end
  end
end
