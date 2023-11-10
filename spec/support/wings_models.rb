# frozen_string_literal: true

return if Hyrax.config.disable_wings
Wings::ModelRegistry.register(CollectionResource, ::Collection)
