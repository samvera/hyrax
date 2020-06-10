# frozen_string_literal: true
module Hyrax
  ##
  # @todo stop swallowing all errors! let clients determine how to handle
  #   failure cases.
  class RedisEventStore < EventStore
    class << self
      # @return [Fixnum, nil] the id of the event, or `nil` on failure(?!)
      def create(action, timestamp)
        event_id = instance.incr("events:latest_id")
        instance.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
        event_id
      rescue Redis::CommandError => e
        logger.error("unable to create event: #{e}")
        nil
      end

      ##
      # @api private
      #
      # @note this is NOT a singleton-ilke `.instance` method, it returns a
      #   `Redis` client.
      #
      # @return [Redis]
      def instance
        if Redis.current.is_a? Redis::Namespace
          Redis.current.namespace = namespace
        else
          Redis.current = Redis::Namespace.new(namespace, redis: Redis.current)
        end
        Redis.current
      end

      ##
      # @api private
      # @return [String]
      def namespace
        Hyrax.config.redis_namespace
      end
    end

    ##
    # @param [Integer] size
    #
    # @return [Enumerable<Hash<Symbol, String>>]
    def fetch(size)
      RedisEventStore.instance.lrange(@key, 0, size).map do |event_id|
        {
          action: RedisEventStore.instance.hget("events:#{event_id}", "action"),
          timestamp: RedisEventStore.instance.hget("events:#{event_id}", "timestamp")
        }
      end
    rescue Redis::CommandError, Redis::CannotConnectError
      RedisEventStore.logger.error("unable to fetch event: #{@key}")
      []
    end

    ##
    # Adds a value to the end of a list identified by key
    #
    # @param [Integer] value
    #
    # @return [Integer, nil] the value successfully pushed; or `nil` on failure(!?)
    def push(value)
      RedisEventStore.instance.lpush(@key, value)
    rescue Redis::CommandError, Redis::CannotConnectError
      RedisEventStore.logger.error("unable to push event: #{@key}")
      nil
    end
  end
end
