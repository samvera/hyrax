module CurationConcerns
  class AdminSetService
    attr_reader :context

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context)
      @context = context
    end

    # @param [Symbol] access :read or :edit
    def select_options(access = :read)
      search_results(access).map do |element|
        [element.to_s, element.id]
      end
    end

    private

      # @param [Symbol] access :read or :edit
      def search_results(access)
        builder = AdminSetSearchBuilder.new(context, access)
        response = context.repository.search(builder)
        response.documents
      end
  end
end
