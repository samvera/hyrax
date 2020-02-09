# frozen_string_literal: true

module Hyrax
  ##
  # @abstract
  # The event store provides an interface to log numbered events into a storage
  # system, e.g. a key-value store.
  #
  # At the class level, we provide a `.create` method for logging event data
  # with incrementing ids. Events have an "action" (a string description of the
  # event), and a (numeric) timestamp. Clients *SHOULD* provide a timestamp that
  # represnts the current application time (i.e. via `Hyrax::TimeService`); see
  # `Hyrax::Event.create_now`.
  #
  # At the instance level, events can be pushed by id onto a list of events for
  # a given topic key, and fetched by the same topic. Initialize an instance
  # with `.for('topic_key')` and use `#push(event_id)` to associate events with
  # the topic.
  #
  # @see Hyrax::RedisEventStore for the default implementation
  # @see Hyrax::Event
  class EventStore
    class << self
      delegate :logger, to: Hyrax

      ##
      # @abstract
      # @api public
      #
      # @note clients should consider using `Hyrax::Event` to manage events instead
      #   of directly interfacing with this method.
      #
      # @param [String] action
      # @param [Integer] timestamp  the time to log the event. usually now.
      #
      # @return [Integer] the id of the event
      def create(_action, _timestamp)
        raise NotImplementedError, 'EventStore.create should be provided by ' \
                                   'a concrete implementation'
      end

      ##
      # @api public
      #
      # @todo this is really just an initializer; deprecate in favor of `.new`?
      #
      # @param [String] key
      def for(key)
        new(key)
      end
    end

    ##
    # @api private
    #
    # @param [String] key
    def initialize(key)
      @key = key
    end

    ##
    # @param [Integer] size
    #
    # @return [Enumerable<Hash<Symbol, String>>]
    def fetch(_size)
      raise NotImplementedError, 'EventStore#fetch should be provided by ' \
                                 'a concrete implementation'
    end

    #
    # Adds a value to the end of a list identified by key
    #
    # @param [Integer] value
    #
    # @return [void]
    def push(_value)
      raise NotImplementedError, 'EventStore#push should be provided by ' \
                                 'a concrete implementation'
    end
  end
end
