# frozen_string_literal: true
module Valkyrie
  # IndexingAdapter is the primary DataMapper object for indexing.
  #  Used to register and locate adapters, for individual
  #  indexing backends (such as solr, elasticsearch, etc)
  class IndexingAdapter
    class_attribute :adapters
    self.adapters = {}
    class << self
      # Register an adapter by a short name.
      # Registering an adapter by a short name makes the adapter easier to find and reference.
      # @param adapter Adapter to register.
      # @param short_name [Symbol] Name to register it under.
      def register(adapter, short_name)
        adapters[short_name.to_sym] = adapter
      end

      # Find an adapter by its short name.
      # @param short_name [Symbol]
      # @return adapter
      # @raise RuntimeError when the given short_name is not found amongst the registered adapters
      def find(short_name)
        symbolized_key = short_name.to_sym
        return adapters[symbolized_key] if adapters.key?(symbolized_key)
        raise KeyError, "Unable to find unregistered adapter `#{short_name}'"
      end
    end
  end
end
