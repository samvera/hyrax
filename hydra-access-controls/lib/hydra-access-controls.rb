require 'active_support'
require 'active-fedora'
require 'blacklight'
require 'cancan'
require 'rails'

module Hydra
  extend ActiveSupport::Autoload
  autoload :AccessControls
  autoload :User
  autoload :AccessControlsEnforcement
  autoload :PolicyAwareAccessControlsEnforcement
  autoload :AccessControlsEvaluation
  autoload :Ability
  autoload :Datastream
  autoload :PolicyAwareAbility
  autoload :AdminPolicy
  autoload :RoleMapperBehavior
  autoload :PermissionsQuery
  autoload :PermissionsCache
  autoload :PermissionsSolrDocument
  class Engine < Rails::Engine
    config.autoload_paths += %W(
      #{config.root}/app/models/concerns
    )
  end

  module ModelMixins
    extend ActiveSupport::Autoload
    autoload :RightsMetadata
  end

  # This error is raised when a user isn't allowed to access a given controller action.
  # This usually happens within a call to AccessControlsEnforcement#enforce_access_controls but can be
  # raised manually.
  class AccessDenied < ::CanCan::AccessDenied; end
end
