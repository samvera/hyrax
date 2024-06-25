# frozen_string_literal: true

require_relative 'persister'
require_relative 'query_service'

module Frigg
  class MetadataAdapter
    include Goddess::Metadata

    def persister
      @persister ||= Frigg::Persister.new(adapter: self)
    end

    # @return [Class] +Valkyrie::Persistence::Postgres::QueryService+
    def query_service
      @query_service ||= Frigg::QueryService.new(
        Valkyrie::Persistence::Fedora::QueryService.new(adapter: self),
        Valkyrie::MetadataAdapter.adapters[:wings_adapter].query_service
      )
    end
  end
end
