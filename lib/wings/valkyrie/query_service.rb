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
        id = ::Valkyrie::ID.new(id.to_s) if id.is_a?(String)
        validate_id(id)
        resource_factory.to_resource(object: ::ActiveFedora::Base.find(id.to_s))
      rescue ::ActiveFedora::ObjectNotFoundError
        raise ::Valkyrie::Persistence::ObjectNotFoundError
      end

      # Constructs a Valkyrie::Persistence::CustomQueryContainer using this query service
      # @return [Valkyrie::Persistence::CustomQueryContainer]
      def custom_queries
        @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
      end

      private

        # Determines whether or not an Object is a Valkyrie ID
        # @param [Object] id
        # @raise [ArgumentError]
        def validate_id(id)
          raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? ::Valkyrie::ID
        end
    end
  end
end
