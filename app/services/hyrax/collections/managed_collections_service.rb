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
        query_builder = Hyrax::Dashboard::CollectionsSearchBuilder.new(scope).rows(0)
        scope.repository.search(query_builder.query).response["numFound"]
      end
    end
  end
end
