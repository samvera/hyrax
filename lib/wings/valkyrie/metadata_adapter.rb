# frozen_string_literal: true

module Wings
  module Valkyrie
    class MetadataAdapter
      def persister
        @persister ||= Wings::Valkyrie::Persister.new(adapter: self)
      end

      # @return [Class] +Valkyrie::Persistence::Postgres::QueryService+
      def query_service
        @query_service ||= Wings::Valkyrie::QueryService.new(adapter: self)
      end

      # @return [Valkyrie::ID] Identifier for this metadata adapter.
      def id
        @id ||= begin
          to_hash = "active_fedora"
          ::Valkyrie::ID.new(Digest::MD5.hexdigest(to_hash))
        end
      end

      # @return [Class] +Valkyrie::Persistence::Postgres::ResourceFactory+
      def resource_factory
        @resource_factory ||= Wings::Valkyrie::ResourceFactory.new(adapter: self)
      end
    end
  end
end
