# frozen_string_literal: true
module Hyrax
  module Ability
    ##
    # Adds methods to the Hyrax ability logic library for authorizing actions
    # related  to Admin Sets ({AdminSet} in ActiveFedora, {Hyrax::AdministrativeSet},
    # for Valkyrie apps).
    #
    # @note this is intended for use with {Hyrax::Ability}, which provides a number of
    #   other ability logic methods, as well as some core behaviors that are needed
    #   here. impartantly {hyrax::Ability#admin?} is expected, as well as some
    #   behavior provided by {{Blacklight::AccessControls::Ability}}.
    #
    # @see Hyrax::Ability
    # @see https://www.rubydoc.info/github/CanCanCommunity/cancancan
    # @see https://www.rubydoc.info/gems/blacklight-access_controls/
    module AdminSetAbility
      # @!group Ability Logic Library

      ##
      # @api public
      #
      # Grant broad access to admin sets for admin users.
      #
      # @note admin status for the current user is defined by `#admin?`.
      #   applications may override this method locally to provide a different
      #   implementation. by default +User#admin?+ is NOT respected here.
      def allow_admins_to_manage_admin_sets
        if admin?
          can :manage, [AdminSet, Hyrax::AdministrativeSet]
          can :manage_any, AdminSet
          can :manage_any, Hyrax::AdministrativeSet
          can :create_any, AdminSet
          can :create_any, Hyrax::AdministrativeSet
          can :view_admin_show_any, AdminSet
          can :view_admin_show_any, Hyrax::AdministrativeSet
        end
      end

      ##
      # @api public
      def admin_set_abilities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        allow_admins_to_manage_admin_sets

        unless admin?
          if Hyrax::Collections::PermissionsService.can_manage_any_admin_set?(ability: self)
            can :manage_any, AdminSet
            can :manage_any, Hyrax::AdministrativeSet
          end
          if Hyrax::CollectionTypes::PermissionsService.can_create_admin_set_collection_type?(ability: self)
            can :create, [AdminSet, Hyrax::AdministrativeSet]
            can :create_any, AdminSet
            can :create_any, Hyrax::AdministrativeSet
          end
          if Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_admin_set?(ability: self)
            can :view_admin_show_any, AdminSet
            can :view_admin_show_any, Hyrax::AdministrativeSet
          end
          # [:edit, :update, :destroy] for AdminSet is controlled by Hydra::Ability #edit_permissions
          can [:edit, :update, :destroy], Hyrax::AdministrativeSet do |admin_set| # for test by solr_doc, see solr_document_ability.rb
            test_edit(admin_set.id)
          end

          can :deposit, AdminSet do |admin_set| # for test by solr_doc, see collection_ability.rb
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: admin_set.id)
          end
          can :deposit, Hyrax::AdministrativeSet do |admin_set| # for test by solr_doc, see collection_ability.rb
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: admin_set.id)
          end

          can :view_admin_show, AdminSet do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: admin_set.id)
          end
          can :view_admin_show, Hyrax::AdministrativeSet do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: admin_set.id)
          end

          # [:read] for AdminSet is controlled by Hydra::Ability #read_permissions
          can :read, Hyrax::AdministrativeSet do |admin_set| # admin show page # for test by solr_doc, see collection_ability.rb
            test_read(admin_set.id)
          end
        end

        # TODO: I'm not sure why this is checked with AdminSet abilities.  It was before the refactor and since I'm not sure what the connection is, I left it here.
        can :review, :submissions do
          can_review_submissions?
        end
      end
    end

    # @!endgroup
  end
end
