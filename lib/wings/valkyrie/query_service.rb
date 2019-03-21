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

      # Find all members of a given resource, and map to Valkyrie Resources
      # @param [Valkyrie::Resource]
      # @param [Valkyrie::ResourceClass]
      # @return [Array<Valkyrie::Resource>]
      def find_members(resource:, model: nil)
        find_model = model.internal_resource.constantize if model
        member_list = resource_factory.from_resource(resource: resource).try(:members)
        return [] unless member_list
        if model
          member_list = member_list.select do |obj|
            obj.class == find_model
          end
        end
        member_list.map do |obj|
          resource_factory.to_resource(object: obj)
        end
      end

      # Find the Valkyrie Resources referenced by another Valkyrie Resource
      # @param [<Valkyrie::Resource>]
      # @param [Symbol] the property holding the references to another resource
      # @return [Array<Valkyrie::Resource>]
      def find_references_by(resource:, property:)
        object = resource_factory.from_resource(resource: resource)
        object.send(property).map do |reference|
          af_id = find_id_for(reference)
          resource_factory.to_resource(object: ::ActiveFedora::Base.find(af_id))
        end
      rescue ActiveFedora::ObjectNotFoundError
        return []
      end

      # Get all resources which link to a resource or id with a given property.
      # @param resource [Valkyrie::Resource] The resource which is being referenced by
      #   other resources.
      # @param resource [Valkyrie::ID] The id of the resource which is being referenced by
      #   other resources.
      # @param property [Symbol] The property which, on other resources, is
      #   referencing the given `resource`. Note: the property needs to be
      #   indexed as a `*_ssim` field
      # @raise [ArgumentError] Raised when the ID is not in the persistence backend.
      # @return [Array<Valkyrie::Resource>] All resources in the persistence backend
      #   which have the ID of the given `resource` in their `property` property. Not
      #   in order.
      def find_inverse_references_by(resource: nil, id: nil, property:)
        raise ArgumentError, "Provide resource or id" unless resource || id
        id ||= resource.alternate_ids.first
        raise ArgumentError, "Resource has no id; is it persisted?" unless id
        uri = ActiveFedora::Base.id_to_uri(id.to_s)
        ActiveFedora::Base.where("#{property}_ssim: \"#{uri}\"").map do |obj|
          resource_factory.to_resource(object: obj)
        end
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

        def find_id_for(reference)
          return ::ActiveFedora::Base.uri_to_id(reference.id) if reference.class == ActiveTriples::Resource
          return reference if reference.class == String
          # not a supported type
          ''
        end
    end
  end
end
