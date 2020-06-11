# frozen_string_literal: true
module Hyrax
  # A mixin module intended to provide an interface into creating the paper trail
  # of activity on the target model of the mixin.
  #
  # @see Hyrax::Event
  module WithEvents
    def stream
      Nest.new(event_class)[to_param]
    end

    # @return [String]
    def event_class
      model_name.name
    end

    ##
    # @param [Integer] size  the maximum number of events to fetch from the log.
    #   Offset by 1; to get one event, use `0`, for two, use `1`, etc...
    #   `-1` gives all events.
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
