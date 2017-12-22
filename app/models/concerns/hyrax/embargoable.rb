module Hyrax
  # A work should be able to be filtered out of search results if it's inactive
  module Embargoable
    extend ActiveSupport::Concern

    # Set the current visibility to match what is described in the embargo.
    # @param embargo [Hyrax::Embargo] the embargo visibility to copy to this work.
    def assign_embargo_visibility(embargo)
      return unless embargo.embargo_release_date
      self.visibility = if embargo.active?
                          embargo.visibility_during_embargo
                        else
                          embargo.visibility_after_embargo
                        end
    end
  end
end
