module Hyrax
  # Provide select options for the copyright status (edm:rights) field
  class RightsStatementService < QaSelectService
    def initialize
      super('rights_statements')
    end
  end
end
