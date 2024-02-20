# frozen_string_literal: true
module Hyrax
  module Ability
    module CollectionAbility
      def collection_abilities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        models = Hyrax::ModelRegistry.collection_classes
        if admin?
          can :manage, models
          can :manage_any, models
          can :create_any, models
          can :view_admin_show_any, models
        else
          can :manage_any, models if Hyrax::Collections::PermissionsService.can_manage_any_collection?(ability: self)

          can :create_any, models if Hyrax::CollectionTypes::PermissionsService.can_create_any_collection_type?(ability: self)

          can :view_admin_show_any, models if Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_collection?(ability: self)

          can [:edit, :update, :destroy], models do |collection|
            test_edit(collection.id)
          end

          can :deposit, models do |collection|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: collection.id)
          end

          can :view_admin_show, models do |collection| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: collection.id)
          end

          can :read, models do |collection| # public show page
            test_read(collection.id)
          end

          can :deposit, ::SolrDocument do |solr_doc|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end

          can :deposit, [::String, ::Valkyrie::ID] do |collection_id|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: collection_id.to_s)
          end

          can :view_admin_show, ::SolrDocument do |solr_doc| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end

          can :view_admin_show, [::String, ::Valkyrie::ID] do |collection_id| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: collection_id.to_s) # checks collections and admin_sets
          end
        end
      end
    end
  end
end
