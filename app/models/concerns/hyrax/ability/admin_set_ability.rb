module Hyrax
  module Ability
    module AdminSetAbility
      def admin_set_abilities # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        can :manage, AdminSet if admin?
        can :manage_any, AdminSet if admin? ||
                                     Hyrax::Collections::PermissionsService.can_manage_any_admin_set?(ability: self)
        can :create_any, AdminSet if admin? ||
                                     Hyrax::CollectionTypes::PermissionsService.can_create_admin_set_collection_type?(ability: self)
        can :view_admin_show_any, AdminSet if admin? ||
                                              Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_admin_set?(ability: self)
        can [:edit, :update, :destroy], AdminSet do |admin_set|
          test_edit(admin_set.id)
        end
        can :deposit, AdminSet do |admin_set|
          Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection: admin_set)
        end
        can :view_admin_show, AdminSet do |admin_set| # admin show page
          Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection: admin_set)
        end
        can :read, AdminSet do |admin_set| # public show page
          test_read(admin_set.id)
        end

        can :review, :submissions do
          can_review_submissions?
        end
      end
    end
  end
end
