# frozen_string_literal: true

module Hyrax
  module WorksHelper
    def available_collections(work:)
      return [] if @current_ability.blank?

      all_collections = Hyrax::CollectionsService.new(self).all_search_results(:deposit)
      return all_collections if work.blank?

      all_collections.reject { |col| work.member_of_collection_ids.include?(col.id) }
    end

    ##
    # This helper allows downstream applications and engines to add additional actions to be
    # rendered in the button row at the top of a work's show page.
    #
    # @example with an additional action
    #  Override this helper and ensure that it loads after Hyrax's helpers.
    #  module WorksHelper
    #    def show_actions_for(*)
    #      super + ["my_new_action"]
    #    end
    #  end
    #  Add the new action partial at app/views/hyrax/base/_show_action_my_new_action.html.erb
    #
    # Each partial receives the presenter as a local and is responsible for deciding
    # whether it renders anything, including any permission check its action requires.
    #
    # @return [Array<String>] the names of additional actions to render
    def show_actions_for(*)
      []
    end
  end
end
