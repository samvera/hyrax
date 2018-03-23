module Hyrax
  # Returns Collections that the current user has permission to use.
  class CollectionsCountService < CountService
    SearchResultForWorkCount = Struct.new(:collection_name, :updated, :work_count, :file_count)

    # This performs a two pass query, first getting the Collections
    # and then getting the work and file counts
    # @param [Symbol] access :read or :edit
    # @param join_field [String] how are we joining the collection ids (by default "isPartOf_ssim")
    # @return [Array<Hyrax::CollectionsService::SearchResultForWorkCount>] a list with document, then work and file count
    def search_results_with_work_count(access, join_field: "member_of_collection_ids_ssim")
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
        last_update = last_updated(results, collection.id)
        SearchResultForWorkCount.new(collection, last_update, counts[collection.id].to_i, file_counts[collection.id].to_i)
      end
    end

    private

      # Count number of files from works
      # @param [Array] results Solr search result
      # @return [Hash] collection id keys and file count values
      def count_files(results)
        file_counts = Hash.new(0)
        results['response']['docs'].each do |doc|
          next if doc['member_of_collection_ids_ssim'].nil?
          doc['member_of_collection_ids_ssim'].each do |id|
            file_counts[id] += doc.fetch('file_set_ids_ssim', []).length
          end
        end
        file_counts
      end

      # Get last updated record from a collection
      def last_updated(results, collection_id)
        dates = []

        results['response']['docs'].each do |coll|
          next if !coll['member_of_collection_ids_ssim'].include?(collection_id) ||
                  coll['system_modified_dtsi'].nil?
          dates << DateTime.parse(coll['system_modified_dtsi']).in_time_zone.strftime("%Y-%m-%d")
        end

        dates.sort!
        dates.last
      end
  end
end
