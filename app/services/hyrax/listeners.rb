# frozen_string_literal: true
module Hyrax
  # When an instance of a listener class is registered with
  # Dry::Events::Publisher#subscribe, its method(s) will be called when a event
  # is published that maps to the method name using the pattern:
  #   on_event_fired => 'event.fired'
  #
  # @see https://dry-rb.org/gems/dry-events/0.2/#event-listeners
  module Listeners
  end
end
