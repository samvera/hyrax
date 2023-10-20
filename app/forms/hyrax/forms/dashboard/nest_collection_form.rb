# frozen_string_literal: true
module Hyrax
  module Forms
    module Dashboard
      # Responsible for validating that both the parent and child are valid for nesting; If so, then
      # also responsible for persisting those changes.
      class NestCollectionForm
        include ActiveModel::Model
        class_attribute :default_query_service, :default_persistence_service, instance_writer: false
        self.default_query_service = Hyrax::Collections::NestedCollectionQueryService
        self.default_persistence_service = Hyrax::Collections::NestedCollectionPersistenceService

        ##
        # @param parent [::Collection, NilClass]
        # @param child [::Collection, NilClass]
        # @param parent_id [String, nil]
        # @param child_id [String, nil]
        # @param context [#can?,#repository,#blacklight_config]
        # @param query_service [Hyrax::Collections::NestedCollectionQueryService]
        # @param persistence_service [Hyrax::Collections::NestedCollectionPersistenceService] responsible for persisting the parent/child relationship
        # rubocop:disable Metrics/ParameterLists
        def initialize(parent: nil,
                       child: nil,
                       parent_id: nil,
                       child_id: nil,
                       context:,
                       query_service: default_query_service,
                       persistence_service: default_persistence_service)
          self.context = context
          self.query_service = query_service
          self.persistence_service = persistence_service
          self.parent = parent || (parent_id.present? && find_parent(parent_id))
          self.child = child || (child_id.present? && find_child(child_id))
        end # rubocop:enable Metrics/ParameterLists

        attr_accessor :parent, :child

        validates :parent, presence: true
        validates :child, presence: true
        validate :parent_and_child_can_be_nested

        def save
          return false unless valid?
          persistence_service.persist_nested_collection_for(parent: parent, child: child, user: context.current_user)
        end

        # when creating a NEW collection, we need to do some basic validation before
        # rerouting to new_dashboard_collection_path to add the new collection as
        # a child. Since we don't yet have a child collection, the valid? option can't be used here.
        def validate_add
          unless nestable?(parent)
            errors.add(:parent, :cannot_have_child_nested)
            return false
          end
          true
        end

        def remove
          if context.can? :edit, parent
            persistence_service.remove_nested_relationship_for(parent: parent, child: child, user: context.current_user)
          else
            errors.add(:parent, :cannot_remove_relationship)
            false
          end
        end

        private

        attr_accessor :query_service, :persistence_service, :context, :collection

        def parent_and_child_can_be_nested
          if nestable?(parent) && nestable?(child)
            return true if query_service.parent_and_child_can_nest?(parent: parent, child: child, scope: context)
            errors.add(:parent, :cannot_have_child_nested)
            errors.add(:child, :cannot_nest_in_parent)
          else
            errors.add(:parent, :is_not_nestable) unless nestable?(parent)
            errors.add(:child, :is_not_nestable) unless nestable?(child)
          end
        end

        def find_parent(parent_id)
          Hyrax.query_service.find_by(id: parent_id)
        end

        def find_child(child_id)
          Hyrax.query_service.find_by(id: child_id)
        end

        def nestable?(collection)
          return false if collection.blank?
          return collection.nestable? if collection.respond_to? :nestable?
          Hyrax::CollectionType.for(collection: collection).nestable?
        end
      end
    end
  end
end
