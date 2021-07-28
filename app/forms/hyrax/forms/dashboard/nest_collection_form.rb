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

        # @param parent [::Collection, NilClass]
        # @param child [::Collection, NilClass]
        # @param context [#can?,#repository,#blacklight_config]
        # @param query_service [Hyrax::Collections::NestedCollectionQueryService]
        # @param persistence_service [Hyrax::Collections::NestedCollectionPersistenceService] responsible for persisting the parent/child relationship
        def initialize(parent: nil, child: nil, context:, query_service: default_query_service, persistence_service: default_persistence_service)
          self.parent = parent
          self.child = child
          self.context = context
          self.query_service = query_service
          self.persistence_service = persistence_service
        end

        attr_accessor :parent, :child

        validates :parent, presence: true
        validates :child, presence: true
        validate :parent_and_child_can_be_nested
        validate :nesting_within_maximum_depth

        def save
          return false unless valid?
          persistence_service.persist_nested_collection_for(parent: parent, child: child)
        end

        ##
        # @deprecated this method is unused by hyrax, and is effectively a
        #   delegation to `Hyrax::Collections::NestedCollectionQueryService`.
        #   if you want to be sure to use nested indexing to generate this list,
        #   use the query service directly.
        #
        # For the given parent, what are all of the available collections that
        # can be added as sub-collection of the parent.
        def available_child_collections
          Deprecation.warn "#{self.class}#available_child_collections " \
                           "is deprecated. the helper of the same name or " \
                           "Hyrax::Collections::NestedCollectionQueryService " \
                           "instead."

          query_service.available_child_collections(parent: parent, scope: context)
        end

        ##
        # @deprecated this method is unused by hyrax, and is effectively a
        #   delegation to `Hyrax::Collections::NestedCollectionQueryService`.
        #   if you want to be sure to use nested indexing to generate this list,
        #   use the query service directly.
        #
        # For the given child, what are all of the available collections to
        # which the child can be added as a sub-collection.
        def available_parent_collections
          Deprecation.warn "#{self.class}#available_parent_collections " \
                           "is deprecated. the helper of the same name or " \
                           "Hyrax::Collections::NestedCollectionQueryService " \
                           "instead."

          query_service.available_parent_collections(child: child, scope: context)
        end

        # when creating a NEW collection, we need to do some basic validation before
        # rerouting to new_dashboard_collection_path to add the new collection as
        # a child. Since we don't yet have a child collection, the valid? option can't be used here.
        def validate_add
          if parent.try(:nestable?)
            nesting_within_maximum_depth
          else
            errors.add(:parent, :cannot_have_child_nested)
            false
          end
        end

        def remove
          if context.can? :edit, parent
            persistence_service.remove_nested_relationship_for(parent: parent, child: child)
          else
            errors.add(:parent, :cannot_remove_relationship)
            false
          end
        end

        private

        attr_accessor :query_service, :persistence_service, :context, :collection

        # ideally we would love to be able to eliminate collections which exceed the
        # maximum nesting depth from the lists of available collections, but the queries
        # needed to make the determination are too expensive to do for every possible
        # collection, so we only test for this situation prior to saving the new
        # relationship.
        def nesting_within_maximum_depth
          return true if query_service.valid_combined_nesting_depth?(parent: parent, child: child, scope: context)
          errors.add(:collection, :exceeds_maximum_nesting_depth)
          false
        end

        def parent_and_child_can_be_nested
          if parent.try(:nestable?) && child.try(:nestable?)
            return true if query_service.parent_and_child_can_nest?(parent: parent, child: child, scope: context)
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
