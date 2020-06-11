# frozen_string_literal: true
module Hyrax
  # Added to allow for the Hyrax::My::WorksController to show only things I have deposited
  # If the work went through mediated deposit, I may no longer have edit access to it.
  class My::WorksSearchBuilder < My::SearchBuilder
    include Hyrax::FilterByType

    # We remove the access controls filter, because some of the works a user has
    # deposited may have gone through a workflow which has removed their ability
    # to edit the work.
    # We remove the active works filter, so a depositor can see submitted works in any state.
    self.default_processor_chain -= [:only_active_works, :add_access_controls_to_solr_params]

    def only_works?
      true
    end
  end
end
