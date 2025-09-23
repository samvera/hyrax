# frozen_string_literal: true

module Hyrax
  module WorksHelper
    def available_collections(work:)
      return [] if @current_ability.blank?

      all_collections = Hyrax::CollectionsService.new(self).search_results(:deposit)
      return all_collections if work.blank?

      all_collections.reject { |col| work.member_of_collection_ids.include?(col.id) }
    end
  end
end
