module Hyrax
  module Forms
    module Dashboard
      # Responsible for validating that both the parent and child are valid for nesting; If so, then
      # also responsible for persisting those changes.
      class NestCollectionForm
        module NestedCollectionQueryService
          def self.available_child_collections(parent:)
            raise NotImplementedError
          end

          def self.available_parent_collections(child:)
            raise NotImplementedError
          end

          def self.parent_and_child_can_nest?(parent:, child:)
            raise NotImplementedError
          end
        end

        module NestedCollectionPersistenceService
          def self.persist_nested_collection_for(parent:, child:)
            raise NotImplementedError
          end
        end

        include ActiveModel::Model
        class_attribute :default_query_service, :default_persistence_service, instance_writer: false
        self.default_query_service = NestedCollectionQueryService
        self.default_persistence_service = NestedCollectionPersistenceService

        # @param parent [Hyrax::Colection, NilClass]
        # @param child [Hyrax::Colection, NilClass]
        # @param query_service [NestedCollectionQueryService]
        # @param persistence_service [#persist_nested_collection_for] responsible for persisting the parent/child relationship
        def initialize(parent: nil, child: nil, query_service: default_query_service, persistence_service: default_persistence_service)
          self.parent = parent
          self.child = child
          self.query_service = query_service
          self.persistence_service = persistence_service
        end

        attr_accessor :parent, :child

        validates :parent, presence: true
        validates :child, presence: true
        validate :parent_and_child_can_be_nested

        def save
          return false unless valid?
          persistence_service.persist_nested_collection_for(parent: parent, child: child)
        end

        # For the given parent, what are all of the available collections that
        # can be added as sub-collection of the parent.
        def available_child_collections
          query_service.available_child_collections(parent: parent)
        end

        # For the given child, what are all of the available collections to
        # which the child can be added as a sub-collection.
        def available_parent_collections
          query_service.available_parent_collections(child: child)
        end

        private

          attr_accessor :query_service, :persistence_service

          def parent_and_child_can_be_nested
            if parent.try(:nestable?) && child.try(:nestable?)
              return true if query_service.parent_and_child_can_nest?(parent: parent, child: child)
              errors.add(:parent, :cannot_have_child_nested)
              errors.add(:child, :cannot_nest_in_parent)
            else
              errors.add(:parent, :is_not_nestable) unless parent.try(:nestable?)
              errors.add(:child, :is_not_nestable) unless child.try(:nestable?)
            end
          end
      end
    end
  end
end
