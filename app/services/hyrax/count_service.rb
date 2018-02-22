module Hyrax
  # Returns Collections that the current user has permission to use.
  class CountService
    attr_reader :context, :search_builder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context, search_builder, model = ::AdminSet)
      @context = context
      @search_builder = search_builder
      @model = model
    end

    # @param [Symbol] access :deposit, :read or :edit
    def search_results(access)
      response = context.repository.search(builder(access))
      response.documents
    end

    protected

    # @param [Symbol] access :read or :edit
    def builder(access)
      search_builder.new(context, access, @model).rows(100)
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