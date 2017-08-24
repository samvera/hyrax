module Hyrax
  module Dashboard
    # Responsible for searching for collections of the same type that are not the given collection
    class NestedCollectionsSearchBuilder < ::Hyrax::CollectionSearchBuilder
      # @param access [Symbol] :edit, :read, :discover
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

      private

        ALLOWED_ACCESS_TYPES = {
          edit: ["edit", "discover", "read"],
          read: ["discover", "read"],
          discover: ["discover", "read"]
        }.freeze
        def extract_discovery_permissions(access)
          ALLOWED_ACCESS_TYPES.fetch(access)
        end
    end
  end
end
