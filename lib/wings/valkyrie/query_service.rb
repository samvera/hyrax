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

      # WARNING: In general, prefer find_by_alternate_identifier over this
      # method.
      #
      # Hyrax uses a shortened noid in place of an id, and this is what is
      # stored in ActiveFedora, which is still the storage backend for Hyrax.
      #
      # If you do not heed this warning, then switch to Valyrie's Postgres
      # MetadataAdapter, but continue passing noids to find_by, you will
      # start getting ObjectNotFoundErrors instead of the objects you wanted
      #
      # Find a record using a Valkyrie ID, and map it to a Valkyrie Resource
      # @param [Valkyrie::ID, String] id
      # @return [Valkyrie::Resource]
      # @raise [Valkyrie::Persistence::ObjectNotFoundError]
      def find_by(id:)
        find_by_alternate_identifier(alternate_identifier: id)
      end

      # Find all work/collection records, and map to Valkyrie Resources
      # @return [Array<Valkyrie::Resource>]
      def find_all
        klasses = Hyrax.config.curation_concerns.append(::Collection)
        objects = ::ActiveFedora::Base.all.select do |object|
          klasses.include? object.class
        end
        objects.map do |id|
          resource_factory.to_resource(object: id)
        end
      end

      # Find all work/collection records of a given model, and map to Valkyrie Resources
      # @param [Valkyrie::ResourceClass]
      # @return [Array<Valkyrie::Resource>]
      def find_all_of_model(model:)
        find_model = model.internal_resource.constantize
        objects = ::ActiveFedora::Base.all.select do |object|
          object.class == find_model
        end
        objects.map do |id|
          resource_factory.to_resource(object: id)
        end
      end

      # Find an array of record using Valkyrie IDs, and map them to Valkyrie Resources
      # @param [Array<Valkyrie::ID, String>] ids
      # @return [Array<Valkyrie::Resource>]
      def find_many_by_ids(ids:)
        ids.each do |id|
          id = ::Valkyrie::ID.new(id.to_s) if id.is_a?(String)
          validate_id(id)
        end
        ids = ids.uniq.map(&:to_s)
        ActiveFedora::Base.where("id: (#{ids.join(' OR ')})").map do |obj|
          resource_factory.to_resource(object: obj)
        end
      end

      def find_by_alternate_identifier(alternate_identifier:)
        alternate_identifier = ::Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
        validate_id(alternate_identifier)
        resource_factory.to_resource(object: ::ActiveFedora::Base.find(alternate_identifier.to_s))
      rescue ::ActiveFedora::ObjectNotFoundError, Ldp::Gone
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
