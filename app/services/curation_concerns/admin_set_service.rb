module CurationConcerns
  class AdminSetService
    def initialize(user)
      @user = user
    end

    def select_options
      search_results.map do |element|
        [element.to_s, element.id]
      end
    end

    def blacklight_config
      ::CatalogController.blacklight_config
    end

    def current_ability
      ::Ability.new(@user)
    end

    private

      def search_results
        builder = AdminSetSearchBuilder.new(self)
        response = repository.search(builder)
        response.documents
      end

      def repository
        ::CatalogController.new.repository
      end
  end
end
