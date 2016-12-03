module Hyrax
  # Provide select options for the copyright status (edm:rights) field
  class RightsStatements < QaSelectService
    def initialize
      super('rights_statements')
    end
  end
end
