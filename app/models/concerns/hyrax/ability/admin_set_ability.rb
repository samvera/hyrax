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

        can [:edit, :update, :destroy], AdminSet do |admin_set| # for test by solr_doc, see solr_document_ability.rb
          test_edit(admin_set.id)
        end

        can :deposit, AdminSet do |admin_set| # for test by solr_doc, see collection_ability.rb
          Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: admin_set.id)
        end

        can :view_admin_show, AdminSet do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
          Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: admin_set.id)
        end

        # TODO: I don't think these are needed anymore.  Should be checking :view_admin_show ability
        can :read, AdminSet do |admin_set| # for test by solr_doc, see solr_document_ability.rb
          test_read(admin_set.id)
        end

        can :review, :submissions do
          can_review_submissions?
        end
      end
    end
  end
end
