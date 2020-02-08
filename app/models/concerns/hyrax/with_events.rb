module Hyrax
  module WithEvents
    def stream
      Nest.new(event_class)[to_param]
    end

    def event_class
      model_name.name
    end

    def events(size = -1)
      event_stream.fetch(size)
    end

    def log_event(event_id)
      event_stream.push(event_id)
    end

    private

      def event_store
        RedisEventStore
      end

      def event_stream
        event_store.for(stream[:event])
      end
  end
end
