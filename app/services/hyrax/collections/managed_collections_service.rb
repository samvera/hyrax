# frozen_string_literal: true
module Hyrax
  module Collections
    module ManagedCollectionsService
      # @api public
      #
      # Count of collections the current user can manage.
      #
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @return [Array<SolrDocument>]
      def self.managed_collections_count(scope:)
        response, _docs = search_service(scope).search_results do |builder|
          builder.rows(0)
        end

        response.response['numFound']
      end

      def self.search_service(scope)
        Hyrax::SearchService.new(
          config: scope.blacklight_config,
          user_params: {},
          current_ability: scope.current_ability,
          scope: scope,
          search_builder_class: Hyrax::Dashboard::CollectionsSearchBuilder
        )
      end
    end
  end
end
