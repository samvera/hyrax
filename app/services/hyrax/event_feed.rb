# frozen_string_literal: true

module Hyrax
  ##
  # @see Hyrax::Event
  # @see Hyrax::RedisEventStore
  class EventFeed
    ##
    # @!attribute [r] model
    attr_reader :model

    ##
    # @param [ActiveModel::Base] model
    # @param [Hyrax::RedisEventStore] event_store
    def initialize(model:, event_store: RedisEventStore)
      @event_store = event_store
      @model = model
    end

    ##
    # @param [Integer] size
    def events
      event_stream.fetch(size)
    end

    ##
    # @param event_id
    def log_event(event_id)
      event_stream.push(event_id)
    end

    private

      def stream
        Nest.new(event_class)[model.to_param]
      end

      def event_namespace
        model.model_name.name
      end

      def event_stream
        @event_store.for(stream[:event])
      end
  end
end
