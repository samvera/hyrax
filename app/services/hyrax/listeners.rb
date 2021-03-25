# frozen_string_literal: true
module Hyrax
  # @note
  #    Did you encounter an exception similar to the following:
  #
  #    "A copy of Hyrax::Listeners::ObjectLifecycleListener has been removed from the module tree but is still active!"
  #
  #    You may need to register a listener as autoload.  See
  #    ./app/services/hyrax/listeners.rb
  module Listeners
    extend ActiveSupport::Autoload

    autoload :AclIndexListener
    autoload :BatchNotificationListener
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
