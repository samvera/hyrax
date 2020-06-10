# frozen_string_literal: true
module Hyrax
  # Provide select options for the copyright status (edm:rights) field
  class RightsStatementService < QaSelectService
    def initialize(_authority_name = nil)
      super('rights_statements')
    end
  end
end
