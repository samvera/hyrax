# frozen_string_literal: true

module Hyrax
  module Specs
    # A spec support class for assisting in spec testing of the
    # Hyrax::Publisher pub/sub behavior.
    #
    # For each registered event, there are two corresponding instance methods
    #
    # 1. `#on_<registered_event>`
    # 2. `#<registered_event>`
    #
    # Then, for any spec you want to make sure Pub/Sub events fire,
    # you can subscribe an instance of Hyrax::Specs::SpyListener.
    # When your spec is completed, unsubscribe the instance.
    #
    # @example For RSpec, assuming "object.deposited" is a registered event
    #   # Note, based on the assumption that "object.deposited", then the
    #   # listener object will have two corresponding methods:
    #   #
    #   # 1. :on_object_deposited - the method called when we publish an event
    #   # 2. :object_deposited    - the attr_reader that captures and exposed
    #   #                           the event for verification
    #   let(:listener) { Hyrax::Specs::SpyListener.new }
    #   before { Hyrax.publisher.subscribe(listener) }
    #   after  { Hyrax.publisher.unsubscribe(listener) }
    #
    #   it "publishes to the listener" do
    #     Hyrax::Publisher.instance.publish("object.deposited", object: object, depositor: user)
    #     expect(listener.object_deposited&.payload).to eq(object: object, depositor: user)
    #   end
    #
    #
    # @see Hyrax::Publisher
    class SpyListener
      Hyrax::Publisher.events.each_value do |registered_event|
        listener_method = registered_event.listener_method
        attr_name = registered_event.listener_method.to_s.sub(/^on_/, '')
        attr_reader attr_name
        define_method listener_method do |published_event|
          instance_variable_set("@#{attr_name}", published_event)
        end
      end
    end

    ##
    # A spy listener that accumulates events, so multiple events published by
    # one unit-under-test can be collected for inspection.
    class AppendingSpyListener
      Hyrax::Publisher.events.each_value do |registered_event|
        listener_method = registered_event.listener_method
        attr_name = registered_event.listener_method.to_s.sub(/^on_/, '')

        define_method attr_name.to_sym do
          instance_variable_get("@#{attr_name}") ||
            instance_variable_set("@#{attr_name}", [])
        end

        define_method listener_method do |published_event|
          send(attr_name.to_sym) << published_event
        end
      end
    end
  end
end
