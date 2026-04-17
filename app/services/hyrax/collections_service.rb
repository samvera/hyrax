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
      builder = search_builder.with(user_params)
      builder.with_access(access) if access
      yield builder if block_given?

      Hyrax::SolrService.fetch_all do |rows, start|
        blacklight_config.repository.search(
          builder.query.merge(rows: rows, start: start, fl: 'id,title_tesim,has_model_ssim')
        )
      end
    end
  end
end
