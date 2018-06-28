module Hyrax
  # Provide select options for the license (dcterms:rights) field
  class LicenseService < QaSelectService
    def initialize(_authority_name = nil)
      super('licenses')
    end
  end
end
