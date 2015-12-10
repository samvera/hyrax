module Sufia
  class Event
    # Creates an event in Redis
    def self.create(action, timestamp)
      store.create(action, timestamp)
    end

    def self.store
      Sufia::RedisEventStore
    end
  end
end
