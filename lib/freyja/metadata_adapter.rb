# frozen_string_literal: true

require_relative 'persister'
require_relative 'query_service'
require_relative 'resource_factory'

module Freyja
  class MetadataAdapter
    include Goddess::Metadata

    ##
    # @return [Freyja::Persister]
    def persister
      @persister ||= Freyja::Persister.new(adapter: self)
    end

    ##
    # @return [Freyja::QueryService, #services]
    def query_service
      @query_service ||= Freyja::QueryService.new(
        Valkyrie::Persistence::Postgres::QueryService.new(adapter: self, resource_factory: resource_factory),
        Valkyrie::MetadataAdapter.adapters[:wings_adapter].query_service
      )
    end

    ##
    # @return [Freyja::ResourceFactory]
    def resource_factory
      @resource_factory ||= Freyja::ResourceFactory.new(adapter: self)
    end
  end
end
