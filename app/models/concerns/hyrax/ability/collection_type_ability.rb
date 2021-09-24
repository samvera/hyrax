# frozen_string_literal: true
module Hyrax
  module Ability
    module CollectionTypeAbility
      def collection_type_abilities
        if admin?
          can :manage, CollectionType
          can :create_collection_type, CollectionType
        else
          can :create_collection_of_type, CollectionType do |collection_type|
            Hyrax::CollectionTypes::PermissionsService.can_create_collection_of_type?(ability: self, collection_type: collection_type)
          end
        end
      end
    end
  end
end
