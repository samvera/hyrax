module Hyrax
  module Ability
    module CollectionAbility
      def collection_abilities # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        can :manage, Collection if admin?
        can :manage_any, Collection if admin? ||
                                       Hyrax::Collections::PermissionsService.can_manage_any_collection?(ability: self)
        can :create_any, Collection if admin? ||
                                       Hyrax::CollectionTypes::PermissionsService.can_create_any_collection_type?(ability: self)
        can :view_admin_show_any, Collection if admin? ||
                                                Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_collection?(ability: self)
        can [:edit, :update, :destroy], Collection do |collection|
          test_edit(collection.id)
        end
        can :deposit, Collection do |collection|
          Hyrax::Collections::PermissionsService.can_deposit_in_collection?(user: current_user, collection: collection)
        end
        can :view_admin_show, Collection do |collection| # admin show page
          Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(user: current_user, collection: collection)
        end
        can :read, Collection do |collection| # public show page
          test_read(collection.id)
        end
      end
    end
  end
end
