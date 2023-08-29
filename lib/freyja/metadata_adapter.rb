# frozen_string_literal: true

require_relative 'query_service'

module Freyja
  class MetadataAdapter
    def persister
      @persister ||= Valkyrie::Persistence::Postgres::Persister.new(adapter: self)
    end

    # @return [Class] +Valkyrie::Persistence::Postgres::QueryService+
    def query_service
      @query_service ||= Freyja::QueryService.new(
        Valkyrie::Persistence::Postgres::QueryService.new(adapter: self, resource_factory: resource_factory),
        Valkyrie::MetadataAdapter.adapters[:wings_adapter].query_service
      )
    end

    # @return [Valkyrie::ID] Identifier for this metadata adapter.
    def id
      @id ||= begin
                to_hash = "migrate_adapter"
                ::Valkyrie::ID.new(Digest::MD5.hexdigest(to_hash))
              end
    end

    # @return [Class] +Valkyrie::Persistence::Postgres::ResourceFactory+
    def resource_factory
      # TODO rob do we need this to be able to read wings?
      @resource_factory ||= Valkyrie::Persistence::Postgres::ResourceFactory.new(adapter: self)
    end
  end
end
