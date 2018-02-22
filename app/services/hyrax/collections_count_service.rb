module Hyrax
  # Returns Collections that the current user has permission to use.
  class CollectionsCountService < CountService
    SearchResultForWorkCount = Struct.new(:collection_name, :updated, :work_count, :file_count)

    # This performs a two pass query, first getting the AdminSets
    # and then getting the work and file counts
    # @param [Symbol] access :read or :edit
    # @param join_field [String] how are we joining the admin_set ids (by default "isPartOf_ssim")
    # @return [Array<Hyrax::AdminSetService::SearchResultForWorkCount>] a list with document, then work and file count
    def search_results_with_work_count(access, join_field: "isPartOf_ssim")
      collections = search_results(access)
      ids = collections.map(&:id).join(',')
      query = "{!terms f=#{join_field}}#{ids}"
      results = ActiveFedora::SolrService.instance.conn.get(
          ActiveFedora::SolrService.select_path,
          params: { fq: query,
                    'facet.field' => join_field }
      )
      counts = results['facet_counts']['facet_fields'][join_field].each_slice(2).to_h
      file_counts = count_files(results)
      collections.map do |collection|
        SearchResultForWorkCount.new(collection.title[0], collection.date_modified, counts[collection.id].to_i, file_counts[collection.id].to_i)
      end
    end
  end
end
