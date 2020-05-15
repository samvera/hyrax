# frozen_string_literal: true

module Hyrax
  ##
  # A custom name for Valkyrie PcdmCollection objects. Route keys are mapped to `collection`
  # not be the same as the model name.
  class CollectionName < Name
    def initialize(klass, namespace = nil, name = nil)
      super

      @route_key          = Collection.model_name.route_key
      @singular_route_key = Collection.model_name.singular_route_key
    end
  end
end
