# frozen_string_literal: true
module Hyrax
  # Finds the child objects contained within a collection
  class MemberWithFilesSearchBuilder < ::SearchBuilder
    class_attribute :from_field
    self.from_field = 'child_object_ids_ssim'
    self.default_processor_chain += [:include_collection_ids, :include_contained_files]

    # This is like include_collection_ids, but it also joins the files.
    def include_contained_files(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!join from=member_ids_ssim to=id}{!join from=child_object_ids_ssim to=id}id:#{collection_id}"
    end

    # include filters into the query to only include the collection memebers
    def include_collection_ids(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!join from=#{from_field} to=id}id:#{collection_id}"
    end

    private

    def collection_id
      blacklight_params.fetch('id')
    end
  end
end
