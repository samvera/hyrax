# frozen_string_literal: true

module Wings
  class MetadataAdapter
    def persister
      Wings::Persister.new(adapter: self)
    end
    # @return [Class] {Valkyrie::Persistence::Postgres::QueryService}
    def query_service
      @query_service ||= Wings::QueryService.new(adapter: self, resource_factory: resource_factory)
    end

    # @return [Class] {Valkyrie::Persistence::Postgres::ResourceFactory}
    def resource_factory
      Wings::ResourceFactory.new(adapter: self)
    end
  end
end
