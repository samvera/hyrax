module CurationConcerns
  class MemberSearchBuilder < ::SearchBuilder
    class_attribute :from_field
    self.from_field = 'member_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:include_collection_ids]

    delegate :collection, to: :scope

    # include filters into the query to only include the collection memebers
    def include_collection_ids(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!join from=#{from_field} to=id}id:#{collection.id}"
    end
  end
end
