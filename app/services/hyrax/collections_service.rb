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
  end
end
