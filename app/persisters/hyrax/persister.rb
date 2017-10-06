# frozen_string_literal: true
module Hyrax
  # This was copied directly from the Valkyrie app. I don't understand why it
  # isn't part of the Valkyrie gem.
  class Persister
    class_attribute :adapter
    self.adapter = Valkyrie.config.metadata_adapter
    class << self
      delegate :save, :delete, :persister, to: :default_adapter

      def default_adapter
        new(adapter: adapter)
      end
    end

    delegate :save, :delete, :persister, to: :adapted_persister
    def initialize(adapter:)
      @adapter = adapter
    end

    def adapted_persister
      adapter.persister
    end
  end
end
