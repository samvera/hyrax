# frozen_string_literal: true
module Hyrax
  module Works
    module ManagedWorksService
      # @api public
      #
      # Count of works the current user can manage.
      #
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @return [Array<SolrDocument>]
      def self.managed_works_count(scope:)
        response, _docs = search_service(scope).search_results do |builder|
          builder.rows(0)
        end
        response.response["numFound"]
      end

      def self.search_service(scope)
        Hyrax::SearchService.new(
          config: scope.blacklight_config,
          user_params: scope.params,
          scope: scope,
          current_ability: scope.current_ability,
          search_builder_class: Hyrax::Dashboard::WorksSearchBuilder
        )
      end
    end
  end
end
