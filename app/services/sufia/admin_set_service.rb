# frozen_string_literal: true
module Sufia
  # Returns AdminSets that the current user has permission to use.
  class AdminSetService < CurationConcerns::AdminSetService
    # This performs a two pass query, first getting the AdminSets and then getting the work counts
    # @param [Symbol] access :read or :edit
    # @return [Array<Array>] a list with document, then work count
    def search_results_with_work_count(access)
      documents = search_results(access)
      ids = documents.map(&:id).join(',')
      join_field = "isPartOf_ssim"
      query = "{!terms f=#{join_field}}#{ids}"
      results = ActiveFedora::SolrService.instance.conn.get(
        ActiveFedora::SolrService.select_path,
        params: { fq: query,
                  'facet.field' => join_field }
      )
      counts = results['facet_counts']['facet_fields'][join_field].each_slice(2).to_h
      documents.map do |doc|
        [doc, counts[doc.id]]
      end
    end
  end
end
