module Hyrax
  module Dashboard
    # Responsible for searching for collections of the same type that are not the given collection
    class NestedCollectionsSearchBuilder < ::Hyrax::CollectionSearchBuilder
      # @param access [Symbol] :edit, :read, :discover - With the given :access what all can
      # @param collection [Collection]
      # @param scope [Object] Typically a controller that responds to #current_ability, #blackligh_config
      def initialize(access:, collection:, scope:)
        super(scope)
        @collection = collection
        @discovery_permissions = extract_discovery_permissions(access)
      end

      # Override for Hydra::AccessControlsEnforcement
      attr_reader :discovery_permissions

      self.default_processor_chain += [:with_pagination, :show_only_other_collections_of_the_same_collection_type]

      def with_pagination(solr_parameters)
        solr_parameters[:rows] = 1000
      end

      def show_only_other_collections_of_the_same_collection_type(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += [
          "-" + ActiveFedora::SolrQueryBuilder.construct_query_for_ids([@collection.id]),
          ActiveFedora::SolrQueryBuilder.construct_query(Collection.collection_type_gid_document_field_name => @collection.collection_type_gid)
        ]
      end

      # If :deposit access is requested, check to see which collections the user has
      # deposit or manage access to.
      # @return [Array<String>] a list of filters to apply to the solr query
      def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
        return super unless permission_types.include?("deposit")
        ["{!terms f=id}#{collection_ids_for_deposit.join(',')}"]
      end

      private

        def collection_ids_for_deposit
          Hyrax::Collections::PermissionsService.collection_ids_for_deposit(ability: current_ability)
        end

        # My intention in this implementation is that if I need at least edit access on the queried document,
        # then I must have one of the following access-levels
        ACCESS_LEVELS_FOR_LEVEL = ActiveSupport::HashWithIndifferentAccess.new(
          edit: ["edit"],
          deposit: ["deposit"],
          read: ["edit", "read"],
          discover: ["edit", "discover", "read"]
        ).freeze
        def extract_discovery_permissions(access)
          ACCESS_LEVELS_FOR_LEVEL.fetch(access)
        end
    end
  end
end
