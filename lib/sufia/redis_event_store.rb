module Sufia
  class RedisEventStore
    def fetch(size)
      $redis.lrange(@key, 0, size).map do |event_id|
        {
          action: $redis.hget("events:#{event_id}", "action"),
          timestamp: $redis.hget("events:#{event_id}", "timestamp")
        }
      end
    rescue
      []
    end

    # Adds a value to the end of a list identified by key
    def push(value)
      $redis.lpush(@key, value)
    rescue
      nil
    end

    def initialize(key)
      @key = key
    end

    def self.for(key)
      new(key)
    end

    # @return [Fixnum] the id of the event
    def self.create(action, timestamp)
      event_id = $redis.incr("events:latest_id")
      $redis.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
      event_id
    rescue => e
      logger.error("unable to create event: #{e}") if logger
      nil
    end
  end
end
