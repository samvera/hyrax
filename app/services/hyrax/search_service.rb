# frozen_string_literal: true

module Hyrax
  ##
  # Returns search results from the repository.
  #
  # @note Adapted from Blacklight 7
  class SearchService
    def initialize(config:, user_params: nil, search_builder_class: config.search_builder_class, **context)
      @blacklight_config = config
      @user_params = user_params || {}
      @search_builder_class = search_builder_class
      @context = context
    end

    # The blacklight_config + controller are accessed by the search_builder
    attr_reader :blacklight_config, :context

    def search_builder
      search_builder_class.new(self)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # a solr query method
    # @yield [search_builder] optional block yields configured SearchBuilder, caller can modify or create new SearchBuilder to be used. Block should return SearchBuilder to be used.
    # @return [Blacklight::Solr::Response] the solr response object
    def search_results
      builder = search_builder.with(user_params)
      builder.page = user_params[:page] if user_params[:page]
      builder.rows = (user_params[:per_page] || user_params[:rows]) if user_params[:per_page] || user_params[:rows]

      builder = yield(builder) if block_given?
      response = repository.search(builder)

      if response.grouped? && grouped_key_for_results
        [response.group(grouped_key_for_results), []]
      elsif response.grouped? && response.grouped.length == 1
        [response.grouped.first, []]
      else
        [response, response.documents]
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # retrieve a document, given the doc id
    # @param [Array{#to_s},#to_s] id
    # @return [Blacklight::Solr::Response, Blacklight::SolrDocument] the solr response object and the first document
    def fetch(id = nil, extra_controller_params = {})
      if id.is_a? Array
        fetch_many(id, extra_controller_params)
      else
        fetch_one(id, extra_controller_params)
      end
    end

    private

    attr_reader :search_builder_class, :user_params, :search_state

    def repository
      blacklight_config.repository || blacklight_config.repository_class.new(blacklight_config)
    end

    def scope
      @context[:scope]
    end

    def method_missing(method_name, *arguments, &block)
      if scope&.respond_to?(method_name)
        Deprecation.warn(self.class, "Calling `#{method_name}` on scope " \
          'is deprecated and will be removed in Blacklight 8. Call #to_h first if you ' \
          ' need to use hash methods (or, preferably, use your own SearchState implementation)')
        scope&.public_send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      scope&.respond_to?(method_name, include_private) || super
    end

    def current_ability
      @current_ability || @context[:current_ability]
    end

    ##
    # Retrieve a set of documents by id
    # @param [Array] ids
    # @param [HashWithIndifferentAccess] extra_controller_params
    def fetch_many(ids, extra_controller_params)
      extra_controller_params ||= {}

      query = search_builder
              .with(user_params)
              .where(blacklight_config.document_model.unique_key => ids)
              .merge(blacklight_config.fetch_many_document_params)
              .merge(extra_controller_params)

      solr_response = repository.search(query)

      [solr_response, solr_response.documents]
    end

    def fetch_one(id, extra_controller_params)
      solr_response = repository.find id, extra_controller_params
      [solr_response, solr_response.documents.first]
    end
  end
end
