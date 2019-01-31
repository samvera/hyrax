# frozen_string_literal: true

module Wings
  module Valkyrie
    class QueryService
      attr_reader :adapter
      extend Forwardable
      def_delegator :adapter, :resource_factory

      # @param adapter [Wings::Valkyrie::MetadataAdapter] The adapter which holds the resource_factory for this query_service.
      def initialize(adapter:)
        @adapter = adapter
      end

      # Find a record using a Valkyrie ID, and map it to a Valkyrie Resource
      # @param [Valkyrie::ID, String] id
      # @return [Valkyrie::Resource]
      # @raise [Valkyrie::Persistence::ObjectNotFoundError]
      def find_by(id:)
        resource_factory.to_resource(object: ::ActiveFedora::Base.find(id.to_s))
      rescue ::ActiveFedora::ObjectNotFoundError
        raise ::Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
