module Sufia
  module WithEvents
    def stream
      Nest.new(self.class.name)[to_param]
    end

    def event_store
      RedisEventStore
    end

    def events(size = -1)
      event_store.for(stream[:event]).fetch(size)
    end

    def log_event(event_id)
      event_store.for(stream[:event]).push(event_id)
    end
  end
end
