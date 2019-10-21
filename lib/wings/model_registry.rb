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
      active_fedora  = active_fedora.constantize if active_fedora.is_a?(String)
      @map[valkyrie] = active_fedora
    rescue NameError => err
      Hyrax.logger.info("Failed to constantize #{active_fedora}")
      raise(err) if ENV['RAILS_ENV'] == 'production'
    end

    def lookup(valkyrie)
      @map[valkyrie]
    end

    def reverse_lookup(active_fedora)
      @map.rassoc(active_fedora)&.first
    end
  end
end
