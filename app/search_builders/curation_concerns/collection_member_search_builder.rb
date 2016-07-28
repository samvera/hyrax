module CurationConcerns
  class CollectionMemberSearchBuilder < ::SearchBuilder
    include CurationConcerns::FilterByType

    class_attribute :collection_membership_field
    self.collection_membership_field = 'member_of_collection_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:member_of_collection]

    delegate :collection, to: :scope

    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{collection.id}"
    end
  end
end
