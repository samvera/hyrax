module CurationConcerns
  class AdminSetService
    attr_reader :context

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context)
      @context = context
    end

    def select_options
      search_results.map do |element|
        [element.to_s, element.id]
      end
    end

    private

      def search_results
        builder = AdminSetSearchBuilder.new(context)
        response = context.repository.search(builder)
        response.documents
      end
  end
end
