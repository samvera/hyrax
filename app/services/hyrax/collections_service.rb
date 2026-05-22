# frozen_string_literal: true
module Hyrax
  class CollectionsService < Hyrax::SearchService
    attr_reader :context

    class_attribute :list_search_builder_class
    self.list_search_builder_class = Hyrax::CollectionSearchBuilder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context)
      super(config: context.blacklight_config, user_params: context.params, search_builder_class: self.class.list_search_builder_class, scope: context)
      @current_ability = context.current_ability
    end

    # @param [Symbol] access :read or :edit
    def search_results(access = nil)
      response, _docs = super() do |builder|
        builder.with_access(access) if access
        builder.rows(100)

        yield builder if block_given?

        builder
      end

      response.documents
    end

    # Like {#search_results}, but pages through every matching collection
    # (up to Hyrax.config.solr_max_results). Use this only for surfaces that
    # need the full set, e.g. the "Add to Collection" dropdown where a user
    # must see every collection they can deposit into.
    #
    # @param [Symbol] access :read or :edit
    # @return [Array<SolrDocument>]
    def all_search_results(access = nil)
      builder = search_builder.with(user_params)
      builder.with_access(access) if access
      yield builder if block_given?

      Hyrax::SolrService.fetch_all do |rows, start|
        blacklight_config.repository.search(builder.query.merge(rows: rows, start: start))
      end
    end
  end
end
