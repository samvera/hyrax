module Hyrax
  # Returns all works, either active or suppressed.
  # This should only be used by an admin user
  class WorksSearchBuilder < ActiveWorksSearchBuilder
    self.default_processor_chain -= [:only_active_works]
  end
end
