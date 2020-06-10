# frozen_string_literal: true
module Hyrax
  module Ability
    module CollectionAbility
      def collection_abilities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        if admin?
          can :manage, ::Collection
          can :manage_any, ::Collection
          can :create_any, ::Collection
          can :view_admin_show_any, ::Collection
        else
          can :manage_any, ::Collection if Hyrax::Collections::PermissionsService.can_manage_any_collection?(ability: self)
          can :create_any, ::Collection if Hyrax::CollectionTypes::PermissionsService.can_create_any_collection_type?(ability: self)
          can :view_admin_show_any, ::Collection if Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_collection?(ability: self)

          can [:edit, :update, :destroy], ::Collection do |collection| # for test by solr_doc, see solr_document_ability.rb
            test_edit(collection.id)
          end

          can :deposit, ::Collection do |collection|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: collection.id)
          end
          can :deposit, ::SolrDocument do |solr_doc|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end

          can :view_admin_show, ::Collection do |collection| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: collection.id)
          end
          can :view_admin_show, ::SolrDocument do |solr_doc| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end

          can :read, ::Collection do |collection| # public show page  # for test by solr_doc, see solr_document_ability.rb
            test_read(collection.id)
          end
        end
      end
    end
  end
end
