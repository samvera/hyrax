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
      # @raise [Hyrax::ObjectNotFoundError]
      def find_by(id:)
        find_by_alternate_identifier(alternate_identifier: id)
      end

      # Find all work/collection records, and map to Valkyrie Resources
      # @return [Array<Valkyrie::Resource>]
      def find_all
        ::ActiveFedora::Base.all.map do |obj|
          resource_factory.to_resource(object: obj)
        end
      end

      # Find all work/collection records of a given model, and map to Valkyrie Resources
      # @param model [Class]
      # @return [Array<Valkyrie::Resource>]
      def find_all_of_model(model:)
        model_class_for(model).all.map do |obj|
          resource_factory.to_resource(object: obj)
        end
      end

      # Find an array of record using Valkyrie IDs, and map them to Valkyrie Resources maintaining order based on given ids
      # @param [Array<Valkyrie::ID, String>] ids
      # @return [Array<Valkyrie::Resource>]
      # NOTE: Ignores non-existent ids.
      def find_many_by_ids(ids:)
        ids.each do |id|
          id = ::Valkyrie::ID.new(id.to_s) if id.is_a?(String)
          validate_id(id)
        end
        resources = []
        ids.uniq.map(&:to_s).each do |id|
          begin
            af_object = ActiveFedora::Base.find(id)
            resources << resource_factory.to_resource(object: af_object)
          rescue ::ActiveFedora::ObjectNotFoundError, Ldp::Gone
            next
          end
        end
        resources
      end

      # Find a record using an alternate ID, and map it to a Valkyrie Resource
      # @param [Valkyrie::ID, String] id
      # @param [boolean] optionally return ActiveFedora object/errors
      # @return [Valkyrie::Resource]
      # @raise [Hyrax::ObjectNotFoundError]
      def find_by_alternate_identifier(alternate_identifier:, use_valkyrie: true)
        alternate_identifier = ::Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
        validate_id(alternate_identifier)
        object = ::ActiveFedora::Base.find(alternate_identifier.to_s)
        return object if use_valkyrie == false
        resource_factory.to_resource(object: object)
      rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone
        raise Hyrax::ObjectNotFoundError
      end

      # Find all members of a given resource, and map to Valkyrie Resources
      # @param resource [Valkyrie::Resource]
      # @param model [Class]
      # @return [Array<Valkyrie::Resource>]
      def find_members(resource:, model: nil)
        return [] unless resource.respond_to?(:member_ids) && resource.member_ids.present?
        all_members = find_many_by_ids(ids: resource.member_ids)
        return all_members unless model
        find_model = model_class_for(model)
        all_members.select { |member_resource| model_class_for(member_resource.class) == find_model }
      end

      # Find the Valkyrie Resources referenced by another Valkyrie Resource
      # @param resource [<Valkyrie::Resource>]
      # @param property [Symbol] the property holding the references to another resource
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
      #   indexed as a `*_ssim` field and indexing either ActiveFedora IDs or full URIs
      # @raise [ArgumentError] Raised when the ID is not in the persistence backend.
      # @return [Array<Valkyrie::Resource>] All resources in the persistence backend
      #   which have the ID of the given `resource` in their `property` property. Not
      #   in order.
      def find_inverse_references_by(resource: nil, id: nil, property:)
        raise ArgumentError, "Provide resource or id" unless resource || id
        id ||= resource.alternate_ids.first
        raise ArgumentError, "Resource has no id; is it persisted?" unless id
        uri = Hyrax::Base.id_to_uri(id.to_s)
        ActiveFedora::Base.where("+(#{property}_ssim: \"#{uri}\" OR #{property}_ssim: \"#{id}\")").map do |obj|
          resource_factory.to_resource(object: obj)
        end
      end

      # Find all parents of a given resource.
      # @param resource [Valkyrie::Resource] The resource whose parents are being searched
      #   for.
      # @return [Array<Valkyrie::Resource>] All resources which are parents of the given
      #   `resource`. This means the resource's `id` appears in their `member_ids`
      #   array.
      def find_parents(resource:)
        id = resource.alternate_ids.first
        ActiveFedora::Base.where("member_ids_ssim: \"#{id}\"").map do |obj|
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
          return ::Hyrax::Base.uri_to_id(reference.id) if reference.class == ActiveTriples::Resource
          return reference if reference.class == String
          # not a supported type
          ''
        end

        def model_class_for(model)
          internal_resource = model.respond_to?(:internal_resource) ? model.internal_resource : nil

          internal_resource&.safe_constantize || ModelRegistry.lookup(model)
        end
    end
  end
end
