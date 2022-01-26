# frozen_string_literal: true

module Hyrax
  ##
  # A custom name for Valkyrie AdministrativeSet objects. Route keys are mapped to `admin_set`
  # not be the same as the model name.
  class AdministrativeSetName < Name
    def initialize(klass, namespace = nil, name = nil)
      super
      @human              = 'AdminSet'
      @i18n_key           = :admin_set
      @param_key          = 'admin_set'
      @plural             = 'admin_sets'
      @route_key          = 'admin_sets'
      @singular_route_key = 'admin_set'
    end
  end
end
