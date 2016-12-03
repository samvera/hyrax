module Hyrax
  class RedisEventStore
    class << self
      def for(key)
        new(key)
      end

      # @return [Fixnum] the id of the event
      def create(action, timestamp)
        event_id = instance.incr("events:latest_id")
        instance.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
        event_id
      rescue Redis::CommandError => e
        logger.error("unable to create event: #{e}")
        nil
      end

      delegate :logger, to: ActiveFedora::Base

      def instance
        if Redis.current.is_a? Redis::Namespace
          Redis.current.namespace = namespace
        else
          Redis.current = Redis::Namespace.new(namespace, redis: Redis.current)
        end
        Redis.current
      end

      def namespace
        Hyrax.config.redis_namespace
      end
    end

    def initialize(key)
      @key = key
    end

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

    # Adds a value to the end of a list identified by key
    def push(value)
      RedisEventStore.instance.lpush(@key, value)
    rescue Redis::CommandError, Redis::CannotConnectError
      RedisEventStore.logger.error("unable to push event: #{@key}")
      nil
    end
  end
end
