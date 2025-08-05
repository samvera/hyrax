# frozen_string_literal: true

require_relative 'persister'
require_relative 'query_service'
require_relative 'resource_factory'

module Frigg
  class MetadataAdapter < Valkyrie::Persistence::Fedora::MetadataAdapter
    include Goddess::Metadata

    ##
    # @return [Frigg::Persister]
    def persister
      @persister ||= Frigg::Persister.new(adapter: self)
    end

    ##
    # @return [Frigg::QueryService, #services]
    def query_service
      @query_service ||= Frigg::QueryService.new(
        Valkyrie::Persistence::Fedora::QueryService.new(adapter: self),
        Valkyrie::MetadataAdapter.adapters[:wings_adapter].query_service
      )
    end

    ##
    # @return [Frigg::ResourceFactory]
    def resource_factory
      @resource_factory ||= Frigg::ResourceFactory.new(adapter: self)
    end
  end
end
