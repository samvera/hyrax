require 'active_support'
# TODO would it be possible to put the require fedora in an after_initialize block like this?
#ActiveSupport.on_load(:after_initialize) do
# This would allow solrizer to load it's config files after the rails logger is up.
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

# Enable the ability/role_mapper classes in the local application to load before the ability/role_mapper classes provided by hydra-access-controls
autoload :Ability, 'ability'
autoload :RoleMapper, 'role_mapper'

