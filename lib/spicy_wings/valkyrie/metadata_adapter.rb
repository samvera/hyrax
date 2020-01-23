# frozen_string_literal: true

module SpicyWings
  module Valkyrie
    class MetadataAdapter
      def persister
        @persister ||= SpicyWings::Valkyrie::Persister.new(adapter: self)
      end

      # @return [Class] {Valkyrie::Persistence::Postgres::QueryService}
      def query_service
        @query_service ||= SpicyWings::Valkyrie::QueryService.new(adapter: self)
      end

      # @return [Valkyrie::ID] Identifier for this metadata adapter.
      def id
        @id ||= begin
          to_hash = "active_fedora"
          ::Valkyrie::ID.new(Digest::MD5.hexdigest(to_hash))
        end
      end

      # @return [Class] {Valkyrie::Persistence::Postgres::ResourceFactory}
      def resource_factory
        @resource_factory ||= SpicyWings::Valkyrie::ResourceFactory.new(adapter: self)
      end
    end
  end
end
