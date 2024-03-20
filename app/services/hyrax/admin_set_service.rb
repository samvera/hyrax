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

    # @param [Symbol] access :deposit, :read or :edit
    def search_results(access)
      response = context.blacklight_config.repository.search(builder(access))
      response.documents
    end

    SearchResultForWorkCount = Struct.new(:admin_set, :work_count, :file_count)

    # This performs a two pass query, first getting the AdminSets
    # and then getting the work and file counts
    # @param [Symbol] access :read or :edit
    # @param join_field [String] how are we joining the admin_set ids (by default "isPartOf_ssim")
    # @return [Array<Hyrax::AdminSetService::SearchResultForWorkCount>] a list with document, then work and file count
    def search_results_with_work_count(access, join_field: "#{Hyrax.config.admin_set_predicate.qname.last}_ssim")
      admin_sets = search_results(access)
      ids = admin_sets.map(&:id).join(',')
      query = "{!terms f=#{join_field}}#{ids}"
      results = Hyrax::SolrService.get(fq: query, rows: 0, 'facet.field': join_field)

      counts = results['facet_counts']['facet_fields'][join_field].each_slice(2).to_h
      file_counts = count_files(admin_sets)
      admin_sets.map do |admin_set|
        SearchResultForWorkCount.new(admin_set, counts[admin_set.id].to_i, file_counts[admin_set.id].to_i)
      end
    end

    private

    # @param [Symbol] access :read or :edit
    def builder(access)
      search_builder.new(context, access).rows(100)
    end

    # Count number of files from admin set works
    # @param [Array] AdminSets to count files in
    # @return [Hash] admin set id keys and file count values
    def count_files(admin_sets)
      file_counts = Hash.new(0)
      file_set_models = Hyrax::ModelRegistry.file_set_rdf_representations
      admin_sets.each do |admin_set|
        query = "{!join from=member_ids_ssim to=id}isPartOf_ssim:#{admin_set.id}"
        file_results = Hyrax::SolrService.get(fq: [query, "{!terms f=has_model_ssim}#{file_set_models.join(',')}"], rows: 0)
        file_counts[admin_set.id] = file_results['response']['numFound']
      end
      file_counts
    end
  end
end
