# Allows you to use CanCan to control access to Models
require 'cancan'
class Ability
  include CanCan::Ability
  include Hydra::Ability
  include Hydra::PolicyAwareAbility
end
