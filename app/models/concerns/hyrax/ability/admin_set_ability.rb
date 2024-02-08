# frozen_string_literal: true
module Hyrax
  module Ability
    module AdminSetAbility
      def admin_set_abilities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        models = [AdminSet, Hyrax::AdministrativeSet, Hyrax.config.admin_set_class].uniq
        if admin?
          models.each do |admin_set_model|
            can :manage, admin_set_model
            can :manage_any, admin_set_model
            can :create_any, admin_set_model
            can :view_admin_show_any, admin_set_model
          end
        else
          models.each { |admin_set_model| can :manage_any, admin_set_model } if
            Hyrax::Collections::PermissionsService.can_manage_any_admin_set?(ability: self)

          models.each { |admin_set_model| can :create_any, admin_set_model } if
            Hyrax::CollectionTypes::PermissionsService.can_create_admin_set_collection_type?(ability: self)

          models.each { |admin_set_model| can :view_admin_show_any, admin_set_model } if
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_admin_set?(ability: self)

          # [:edit, :update, :destroy] for AdminSet is controlled by Hydra::Ability #edit_permissions
          models.each do |admin_set_model|
            can [:edit, :update, :destroy], admin_set_model do |admin_set| # for test by solr_doc, see solr_document_ability.rb
              test_edit(admin_set.id)
            end

            can :deposit, admin_set_model do |admin_set| # for test by solr_doc, see collection_ability.rb
              Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: admin_set.id)
            end

            can :view_admin_show, admin_set_model do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
              Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: admin_set.id)
            end

            # [:read] for AdminSet is controlled by Hydra::Ability #read_permissions
            can :read, admin_set_model do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
              test_read(admin_set.id)
            end
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
