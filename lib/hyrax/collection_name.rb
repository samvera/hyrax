# frozen_string_literal: true

module Hyrax
  ##
  # A custom name for Valkyrie PcdmCollection objects. Route keys are mapped to `collection`
  # not be the same as the model name.
  class CollectionName < Name
    def initialize(klass, namespace = nil, name = nil)
      super

      @human              = 'Collection'
      @route_key          = 'collections'
      @singular_route_key = 'collection'
    end
  end
end
