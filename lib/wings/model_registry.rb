# frozen_string_literal: true

module Wings
  ##
  # This registry provides an off-ramp for legacy ActiveFedora models.
  #
  # New valkyrie models can be defined manually and registered as an analogue
  # of an existing `ActiveFedora::Base` implementer. This allows Wings to cast
  # the new model to the legacy model when saving, ensuring backwards compatible
  # data on save.
  #
  # Several models from Hyrax components have default mappings provided by Wings.
  #
  # @example
  #   Wings::ModelRegistry.register(NewValkyrieModel, OldActiveFedoraModel)
  #
  #   Wings::ModelRegistry.lookup(NewValkyrieModel) # => OldActiveFedoraModel
  #   Wings::ModelRegistry.reverse_lookup(OldActiveFedoraModel) # => NewValkyrieModel
  #
  class ModelRegistry
    include Singleton

    def self.register(*args)
      instance.register(*args)
    end

    def self.unregister(*args)
      instance.unregister(*args)
    end

    def self.lookup(*args)
      instance.lookup(*args)
    end

    def self.reverse_lookup(*args)
      instance.reverse_lookup(*args)
    end

    def initialize
      @map = {}
    end

    def register(valkyrie, active_fedora)
      @map[valkyrie.name] = active_fedora.name
    end

    def unregister(valkyrie)
      @map.delete(valkyrie.name)
    end

    def lookup(valkyrie)
      valkyrie = valkyrie._canonical_valkyrie_model if
        valkyrie.respond_to?(:_canonical_valkyrie_model)

      @map[valkyrie.name]&.safe_constantize ||
        ActiveFedoraConverter::DefaultWork(valkyrie)
    end

    def reverse_lookup(active_fedora)
      @map.rassoc(active_fedora.name)&.first&.safe_constantize
    end
  end
end
