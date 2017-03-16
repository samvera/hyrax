# frozen_string_literal: true
module Hyrax
  # Returns AdminSets that the current user has permission to use.
  class AdminSetService
    attr_reader :context, :search_builder
    class_attribute :default_search_builder
    self.default_search_builder = Hyrax::AdminSetSearchBuilder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context, search_builder = default_search_builder)
      @context = context
      @search_builder = search_builder
    end

    # @param [Symbol] access :read or :edit
    def search_results(access)
      response = context.repository.search(builder(access))
      response.documents
    end

    SearchResultForWorkCount = Struct.new(:admin_set, :work_count, :file_count)

    # This performs a two pass query, first getting the AdminSets
    # and then getting the work and file counts
    # @param [Symbol] access :read or :edit
    # @param join_field [String] how are we joining the admin_set ids (by default "isPartOf_ssim")
    # @return [Array<Hyrax::AdminSetService::SearchResultForWorkCount>] a list with document, then work and file count
    def search_results_with_work_count(access, join_field: "isPartOf_ssim")
      admin_sets = search_results(access)
      ids = admin_sets.map(&:id).join(',')
      query = "{!terms f=#{join_field}}#{ids}"
      results = ActiveFedora::SolrService.instance.conn.get(
        ActiveFedora::SolrService.select_path,
        params: { fq: query,
                  'facet.field' => join_field }
      )
      counts = results['facet_counts']['facet_fields'][join_field].each_slice(2).to_h
      file_counts = count_files(results)
      admin_sets.map do |admin_set|
        SearchResultForWorkCount.new(admin_set, counts[admin_set.id].to_i, file_counts[admin_set.id].to_i)
      end
    end

    private

      # @param [Symbol] access :read or :edit
      def builder(access)
        search_builder.new(context, access)
      end

      # Count number of files from admin set works
      # @param [Array] results Solr search result
      # @return [Hash] admin set id keys and file count values
      def count_files(results)
        file_counts = Hash.new(0)
        results['response']['docs'].each do |doc|
          doc['isPartOf_ssim'].each do |id|
            file_counts[id] += doc.fetch('file_set_ids_ssim', []).length
          end
        end
        file_counts
      end
  end
end
