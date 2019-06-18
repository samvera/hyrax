module Hyrax
  ##
  # Finds Resources using the configured query service
  class ResourceFinder
    ##
    # @!attribute [r] query_service
    #   @return [#find_by]
    attr_reader :query_service

    ##
    # @param query_service [#find_by]
    def initialize(query_service: Valkyrie.config.metadata_adapter.query_service)
      @query_service = query_service
    end

    ##
    # @param id [String]
    #
    # @return [Valkyrie::Resource]
    # @raise  [Valkyrie::Persistence::ObjectNotFoundError]
    def find(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end
  end
end
