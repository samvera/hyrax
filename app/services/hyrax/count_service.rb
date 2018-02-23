module Hyrax
  class CountService
    attr_reader :context, :search_builder, :model
    class_attribute :default_search_builder
    self.default_search_builder = Hyrax::AdminSetSearchBuilder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context, search_builder = default_search_builder, model = ::AdminSet)
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
  end
end

# member_of_collections_ssim