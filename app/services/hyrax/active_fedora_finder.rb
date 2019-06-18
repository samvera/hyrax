module Hyrax
  ##
  # Finds `ActiveFedora::Base` resources by id.
  #
  # Replaces `ActiveFedora::Base.find`, with a query-side interface like that of
  # `ResourceFinder`. The response is an ActiveFedora model.
  #
  # The `query_service` provided at initialization is for interface
  # compatibility only; this class provides no guarantee that the provided query
  # service will be used to execute the query.
  class ActiveFedoraFinder
    ##
    # @!attribute [r] query_service
    #   @return [#find_by]
    attr_reader :query_service

    ##
    # @param query_service [#find_by]
    def initialize(query_service: Valkyrie.config.metadata_adapter.query_service)
      @query_service   = query_service
      @resource_finder = ResourceFinder.new(query_service: query_service)
    end

    ##
    # @param id [#to_s]
    #
    # @return [ActiveFedora::Base]
    def find(id)
      # resource = resource_finder.find(id.to_s)

      # Wings::ActiveFedoraConverter
      #   .new(resource: resource)
      #   .convert
      ActiveFedora::Base.find(id)
    end
  end
end
