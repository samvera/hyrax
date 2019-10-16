module Hyrax
  module CustomQueries
    module Navigators
      class FindFiles
        # Use:
        #   Hyrax.query_service.custom_queries.find_files(resource: file_set_resource)

        def self.queries
          [:find_files]
        end

        def initialize(query_service:)
          @query_service = query_service
        end

        attr_reader :query_service
        delegate :resource_factory, to: :query_service

        # Find file ids of a given resource, and map to file resources
        # @param resource [Valkyrie::Resource] typically, this will be an instance of Hyrax::FileSet
        # @return [Array<Valkyrie::Resource>] typically, file resources will be instances of Hyrax::FileMetadata
        def find_files(resource:)
          return [] unless resource.respond_to?(:file_ids) && resource.file_ids.present?
          query_service.find_many_by_ids(ids: resource.file_ids)
        end
      end
    end
  end
end
