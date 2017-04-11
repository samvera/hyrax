module Hyrax
  # Allow for the Hyrax::My::WorksController to show only things I have edit access to
  class My::WorksSearchBuilder < Hyrax::My::SearchBuilder
    include Hyrax::FilterByType

    def only_works?
      true
    end

    # We remove the access controls filter, because some of the works a user has
    # deposited may have gone through a workflow which has removed their ability
    # to edit the work.
    self.default_processor_chain -= [:add_access_controls_to_solr_params]
  end
end
