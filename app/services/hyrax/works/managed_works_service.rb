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
        query_builder = Hyrax::Dashboard::WorksSearchBuilder.new(scope).rows(0)
        scope.repository.search(query_builder.query).response["numFound"]
      end
    end
  end
end
