# frozen_string_literal: true

return if Hyrax.config.disable_wings

# Clear existing Collection mapping to allow reverse lookups to resolve CollectionResource
Wings::ModelRegistry.register(Hyrax::PcdmCollection, ActiveFedora::Base)
Wings::ModelRegistry.register(CollectionResource, ::Collection)
