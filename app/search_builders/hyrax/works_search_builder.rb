module Hyrax
  # Finds a list of works. It returns no result if you don't have
  # access to the requested work.  If the work is suppressed (due to being in a
  # workflow), then it checks to see if the current_user has any workflow role
  # on the given work.
  class WorksSearchBuilder < Hyrax::SearchBuilder
    include Hyrax::FilterByType

    def only_works?
      true
    end
  end
end
