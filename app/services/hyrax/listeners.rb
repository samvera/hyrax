# frozen_string_literal: true
module Hyrax
  # @note
  #    Did you encounter an exception similar to the following:
  #
  #    "A copy of Hyrax::Listeners::ObjectLifecycleListener has been removed from the module tree but is still active!"
  #
  #    You may need to register a listener as autoload.  See
  #    ./app/services/hyrax/listeners.rb
  #
  # When an instance of a listener class is registered with
  # Dry::Events::Publisher#subscribe, its method(s) will be called when a event
  # is published that maps to the method name using the pattern:
  #   on_event_fired => 'event.fired'
  #
  # @see https://dry-rb.org/gems/dry-events/0.2/#event-listeners
  module Listeners
    extend ActiveSupport::Autoload

    autoload :ACLIndexListener
    autoload :ActiveFedoraACLIndexListener
    autoload :BatchNotificationListener
    autoload :FileListener
    autoload :FileMetadataListener
    autoload :FileSetLifecycleListener
    autoload :FileSetLifecycleNotificationListener
    autoload :MemberCleanupListener
    autoload :MetadataIndexListener
    autoload :ObjectLifecycleListener
    autoload :ProxyDepositListener
    autoload :TrophyCleanupListener
    autoload :WorkflowListener
  end
end
