module CurationConcerns
  # Provide select options for the license (dcterms:rights) field
  class LicenseService < QaSelectService
    def initialize
      super('licenses')
    end
  end
end
