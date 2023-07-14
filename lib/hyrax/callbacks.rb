# frozen_string_literal: true

module Hyrax
  ##
  # @deprecated
  module Callbacks
    extend ActiveSupport::Concern

    included do
      # Define class instance variable as endpoint to the
      # Callback::Registry api.
      @callback = Registry.new
    end

    module ClassMethods
      # Reader for class instance variable containing callback definitions.
      def callback
        @callback
      end
    end

    # Accessor to Callback::Registry api for instances.
    def callback
      self.class.callback
    end

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
      def set(hook, warn: true, &block)
        Deprecation.warn(self, warning_for_set) if warn
        raise NoBlockGiven, "a block is required when setting a callback" unless block_given?
        @callbacks[hook] = proc(&block)
      end

      # Returns true if a callback has been defined for a given hook.
      def set?(hook)
        enabled?(hook) && @callbacks[hook].respond_to?(:call)
      end

      # Runs the callback defined for a given hook, with the arguments provided
      def run(hook, *args, warn: true, **opts)
        Deprecation.warn(self, warning_for_run) if warn
        raise NotEnabled unless enabled?(hook)
        return nil unless set?(hook)
        @callbacks[hook].call(*args, **opts)
      end

      private

      def warning_for_set
        "Hyrax.config.callback is deprecated; register your callback handler " \
          "as a listener on Hyrax.publisher instead. See Hyrax::Publisher " \
          "and Dry::Events"
      end

      def warning_for_run
        "Hyrax.config.callback is deprecated; to trigger handlers publish " \
          "events to Hyrax.publisher instead of running callbacks. See " \
          "Hyrax::Publisher and Dry::Events"
      end
    end

    # Custom exceptions
    class NotEnabled < StandardError; end
    class NoBlockGiven < StandardError; end
  end
end
