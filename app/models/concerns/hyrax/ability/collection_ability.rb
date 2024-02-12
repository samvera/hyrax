# frozen_string_literal: true
module Hyrax
  module Ability
    module CollectionAbility
      def collection_models
        @collection_models ||= ["::Collection".safe_constantize, Hyrax::PcdmCollection, Hyrax.config.collection_class].compact.uniq
      end

      def collection_abilities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if admin?
          can :manage, collection_models
          can :manage_any, collection_models
          can :create_any, collection_models
          can :create, collection_models
          can :view_admin_show_any, collection_models
        else
          if Hyrax::Collections::PermissionsService.can_manage_any_collection?(ability: self)
            can :manage_any, collection_models
          end

          if Hyrax::CollectionTypes::PermissionsService.can_create_any_collection_type?(ability: self)
            can :create_any, collection_models
          end

          can(:view_admin_show_any, collection_models) if Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_collection?(ability: self)

          can([:edit, :update, :destroy], collection_models) do |collection|
            test_edit(collection.id)
          end

          can(:deposit, collection_models) do |collection|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: collection.id)
          end

          can(:view_admin_show, collection_models) do |collection| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: collection.id)
          end

          can(:read, collection_models) do |collection| # public show page
            test_read(collection.id)
          end

          can(:deposit, ::SolrDocument) do |solr_doc|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end

          can(:deposit, String) do |collection_id|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: collection_id)
          end

          can(:view_admin_show, ::SolrDocument) do |solr_doc| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end
        end
      end
    end
  end
end
