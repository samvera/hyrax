# frozen_string_literal: true
module Hyrax
  # Returns all works, either active or suppressed.
  # This should only be used by an admin user
  class WorksSearchBuilder < Hyrax::SearchBuilder
    include Hyrax::FilterByType
    self.default_processor_chain -= [:only_active_works]

    def only_works?
      true
    end
  end
end
