module Hyrax
  # This search builder requires that a accessor named "collection" exists in the scope
  # TODO it would be better to pass collection_id in.
  class CollectionMemberSearchBuilder < ::SearchBuilder
    include Hyrax::FilterByType

    class_attribute :collection_membership_field
    self.collection_membership_field = 'member_of_collection_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:member_of_collection]

    delegate :collection, to: :scope

    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{collection_id}"
    end

    private

      def collection_id
        collection.id || raise("Collection does not have an identifier")
      end
  end
end
