# frozen_string_literal: true

return if Hyrax.config.disable_wings

# Clear existing Collection mapping to allow reverse lookups to resolve CollectionResource.
# Then restore PcdmCollection for any code directly using that model.
Wings::ModelRegistry.unregister(Hyrax::PcdmCollection)
Wings::ModelRegistry.register(CollectionResource, ::Collection)
Wings::ModelRegistry.register(Hyrax::PcdmCollection, ::Collection)
