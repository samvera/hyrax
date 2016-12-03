module Hyrax
  module Callbacks
    class Registry
      attr_reader :callbacks

      def initialize
        @callbacks = {}
      end

      # Enables a callback by specifying one or more hooks.
      def enable(hook, *more_hooks)
        ([hook] + more_hooks).each { |h| @callbacks[h] ||= nil }
      end

      # Returns all enabled callback hooks.
      def enabled
        @callbacks.keys
      end

      # Returns true if the callback hook has been enabled.
      def enabled?(hook)
        @callbacks.key? hook
      end

      # Defines a callback for a given hook.
      def set(hook, &block)
        raise NoBlockGiven, "a block is required when setting a callback" unless block_given?
        @callbacks[hook] = proc(&block)
      end

      # Returns true if a callback has been defined for a given hook.
      def set?(hook)
        enabled?(hook) && @callbacks[hook].respond_to?(:call)
      end

      # Runs the callback defined for a given hook, with the arguments provided
      def run(hook, *args)
        raise NotEnabled unless enabled?(hook)
        return nil unless set?(hook)
        @callbacks[hook].call(*args)
      end
    end

    # Custom exceptions
    class NotEnabled < StandardError; end
    class NoBlockGiven < StandardError; end
  end
end
