require 'active_support'
require 'active-fedora'
require 'cancan'

module Hydra
  extend ActiveSupport::Autoload
  autoload :User
  autoload :AccessControlsEnforcement
  autoload :PolicyAwareAccessControlsEnforcement
  autoload :AccessControlsEvaluation
  autoload :Ability
  autoload :Datastream
  autoload :PolicyAwareAbility
  autoload :AdminPolicy
  autoload :RoleMapperBehavior

  module ModelMixins
    extend ActiveSupport::Autoload
    autoload :RightsMetadata
  end

  # This error is raised when a user isn't allowed to access a given controller action.
  # This usually happens within a call to AccessControlsEnforcement#enforce_access_controls but can be
  # raised manually.
  class AccessDenied < ::CanCan::AccessDenied; end

end
ActiveSupport.on_load(:after_initialize) do
  # Enable the ability class in the local application to load before the ability class provided by hydra-access-controls
  require 'ability'
end
require 'role_mapper'

