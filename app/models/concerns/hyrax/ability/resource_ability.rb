# frozen_string_literal: true
module Hyrax
  module Ability
    module ResourceAbility
      def resource_abilities
        if admin?
          can [:manage], ::Hyrax::Resource
        else
          can [:edit, :update, :destroy], ::Hyrax::Resource do |res|
            test_edit(res.id)
          end
          can :read, ::Hyrax::Resource do |res|
            test_read(res.id)
          end
        end
      end
    end
  end
end
