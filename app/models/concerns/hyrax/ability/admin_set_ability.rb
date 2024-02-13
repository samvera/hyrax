# frozen_string_literal: true
module Hyrax
  module Ability
    module AdminSetAbility
      def admin_set_abilities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        models = Hyrax::ModelRegistry.admin_set_classes
        if admin?
          can :manage, models
          can :manage_any, models
          can :create_any, models
          can :view_admin_show_any, models
        else
          can :manage_any, models if Hyrax::Collections::PermissionsService.can_manage_any_admin_set?(ability: self)
          if Hyrax::CollectionTypes::PermissionsService.can_create_admin_set_collection_type?(ability: self)
            can :create, models
            can :create_any, models
          end
          can :view_admin_show_any, models if Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_admin_set?(ability: self)
          # [:edit, :update, :destroy] for AdminSet is controlled by Hydra::Ability #edit_permissions
          can [:edit, :update, :destroy], models do |admin_set| # for test by solr_doc, see solr_document_ability.rb
            test_edit(admin_set.id)
          end

          can :deposit, models do |admin_set| # for test by solr_doc, see collection_ability.rb
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: admin_set.id)
          end

          can :view_admin_show, models do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: admin_set.id)
          end

          # [:read] for AdminSet is controlled by Hydra::Ability #read_permissions
          can :read, models do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
            test_read(admin_set.id)
          end
        end

        # TODO: I'm not sure why this is checked with AdminSet abilities.  It was before the refactor and since I'm not sure what the connection is, I left it here.
        can :review, :submissions do
          can_review_submissions?
        end
      end
    end
  end
end
