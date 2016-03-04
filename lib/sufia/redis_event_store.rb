module Sufia
  class RedisEventStore
    def fetch(size)
      Redis.current.lrange(@key, 0, size).map do |event_id|
        {
          action: Redis.current.hget("events:#{event_id}", "action"),
          timestamp: Redis.current.hget("events:#{event_id}", "timestamp")
        }
      end
    rescue
      []
    end

    # Adds a value to the end of a list identified by key
    def push(value)
      Redis.current.lpush(@key, value)
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
      event_id = Redis.current.incr("events:latest_id")
      Redis.current.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
      event_id
    rescue => e
      logger.error("unable to create event: #{e}") if logger
      nil
    end
  end
end
