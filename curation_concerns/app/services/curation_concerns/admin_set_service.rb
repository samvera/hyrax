module CurationConcerns
  class AdminSetService
    attr_reader :context, :search_builder
    class_attribute :default_search_builder
    self.default_search_builder = AdminSetSearchBuilder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context, search_builder = default_search_builder)
      @context = context
      @search_builder = search_builder
    end

    # @param [Symbol] access :read or :edit
    def select_options(access = :read)
      search_results(access).map do |element|
        [element.to_s, element.id]
      end
    end

    # @param [Symbol] access :read or :edit
    def search_results(access)
      response = context.repository.search(builder(access))
      response.documents
    end

    protected

      # @param [Symbol] access :read or :edit
      def builder(access)
        search_builder.new(context, access)
      end
  end
end
