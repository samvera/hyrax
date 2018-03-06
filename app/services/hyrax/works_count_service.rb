module Hyrax
  # Returns Works that the current user has permission to use.
  class WorksCountService < CountService
    SearchResultForWorkCount = Struct.new(:work_name, :updated, :work_views, :work_type, :visibility)

    # This performs a two pass query, first getting the AdminSets
    # and then getting the work and file counts
    # @param [Symbol] access :read or :edit
    # @param join_field [String] how are we joining the admin_set ids (by default "isPartOf_ssim")
    # @return [Array<Hyrax::AdminSetService::SearchResultForWorkCount>] a list with document, then work and file count
    def search_results_with_work_count(access, join_field: "isPartOf_ssim")
      works = search_results(access)
      ids = works.map(&:id).join(',')
      query = "{!terms f=#{join_field}}#{ids}"
      results = ActiveFedora::SolrService.instance.conn.get(
          ActiveFedora::SolrService.select_path,
          params: { fq: query,
                    'facet.field' => join_field }
      )
      counts = results['facet_counts']['facet_fields'][join_field].each_slice(2).to_h
      works.map do |work|
        SearchResultForWorkCount.new(work.title[0], work.date_modified, counts[work.id].to_i, work.type, work.visibility)
      end
    end
  end
end