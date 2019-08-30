module Hyrax
  module CustomQueries
    class Wings
      # Holds custom queries for wings
      # Use:
      # Hyrax.query_service.custom_queries.find_many_by_alternate_ids(alternate_ids: ids, use_valkyrie: true)

      def self.queries
        [:find_many_by_alternate_ids, :find_access_control_for]
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      # implements a combination of two Valkyrie queries:
      # => find_many_by_ids & find_by_alternate_identifier
      # @param [Enumerator<#to_s>] ids
      # @param [boolean] defaults to true; optionally return ActiveFedora::Base objects if false
      # @return [Array<Valkyrie::Resource>, Array<ActiveFedora::Base>]
      def find_many_by_alternate_ids(alternate_ids:, use_valkyrie: true)
        af_objects = ActiveFedora::Base.find(alternate_ids.map(&:to_s))
        return af_objects unless use_valkyrie == true

        af_objects.map do |af_object|
          resource_factory.to_resource(object: af_object)
        end
      end

      ##
      # Wings needs special handling for this query, since `Hydra::AccessControl`
      # relationship direction is inverted from the `Hyrax::AccessControl`. We
      # need to query from the `access_control_id` stored on the resource,
      # instead of doing an `inverse_references_by` lookup.
      #
      # @param [Valkyrie::Resource] resource

      # @return [Valkyrie::Resource]
      # @raise [Valkyrie::Persistence::ObjectNotFoundError]
      def find_access_control_for(resource:)
        if resource.respond_to?(:access_control_id)
          raise Valkyrie::Persistence::ObjectNotFoundError if resource.access_control_id.blank?
          result = query_service.find_by(id: resource.access_control_id)
          result.access_to = resource.id # access_to won't be set in wings if there are no permissions
          result
        else
          raise Valkyrie::Persistence::ObjectNotFoundError,
                "#{resource.internal_resource} is not a `Hydra::AccessControls::Permissions` implementer"
        end
      end
    end
  end
end
