module Hyrax
  # Class to build count services for hyrax object types
  # @abstract
  class CountService
    attr_reader :context, :search_builder, :model
    class_attribute :default_search_builder
    self.default_search_builder = Hyrax::AdminSetSearchBuilder
    MAX_ROWS = 100

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

    # @abstract
    def search_results_with_work_count
      raise NotImplementedError, "This method is abstract. #{name} must implemented."
    end

    protected

      # @param [Symbol] access :read or :edit
      def builder(access)
        search_builder.new(context, access, @model).rows(MAX_ROWS)
      end
  end
end
