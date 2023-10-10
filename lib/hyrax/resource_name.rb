# frozen_string_literal: true

module Hyrax
  ##
  # A custom name for Valkyrie Resource objects. Route keys for resources may
  # not be the same as the model name.
  class ResourceName < Name
    def initialize(klass, namespace = nil, name = nil)
      super
      return unless defined?(Wings::ModelRegistry)

      legacy_model = Wings::ModelRegistry.lookup(klass)
      return unless legacy_model

      @route_key          = legacy_model.model_name.route_key
      @singular_route_key = legacy_model.model_name.singular_route_key
    end

    def human
      super.titleize
    end
  end
end
