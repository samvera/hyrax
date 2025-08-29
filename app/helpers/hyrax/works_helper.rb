# frozen_string_literal: true

module Hyrax
  module WorksHelper
    def available_collections(work:)
      all_collections = Hyrax::CollectionsService.new(self).search_results(:deposit)
      return all_collections if work.blank?

      all_collections.reject { |col| col.id.in?(work.member_of_collection_ids) }
    end
  end
end
