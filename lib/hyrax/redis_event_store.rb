# frozen_string_literal: true
module Hyrax
  ##
  # @todo stop swallowing all errors! let clients determine how to handle
  #   failure cases.
  class RedisEventStore < EventStore
    class << self
      # @return [Fixnum, nil] the id of the event, or `nil` on failure(?!)
      def create(action, timestamp)
        instance.then do |redis|
          event_id = redis.incr("events:latest_id")
          redis.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
          event_id
        end
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
        if  Hyrax.config.redis_connection&.is_a?(Redis::Namespace)
          c = Hyrax.config.redis_connection
          c.namespace = namespace
          c
        elsif Hyrax.config.redis_connection
          Hyrax.config.redis_connection
        else
          Redis::Namespace.new(namespace, redis: Redis.new)
        end
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
      Hyrax::RedisEventStore.instance.then do |redis|
        redis.lrange(@key, 0, size).map do |event_id|
          {
            action: redis.hget("events:#{event_id}", "action"),
            timestamp: redis.hget("events:#{event_id}", "timestamp")
          }
        end
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
      Hyrax::RedisEventStore.instance.then { |r| r.lpush(@key, value) }
    rescue Redis::CommandError, Redis::CannotConnectError
      RedisEventStore.logger.error("unable to push event: #{@key}")
      nil
    end
  end
end
