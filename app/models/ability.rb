# Allows you to use CanCan to control access to Models
class Ability
  include CanCan::Ability
  include Hydra::Ability
end
