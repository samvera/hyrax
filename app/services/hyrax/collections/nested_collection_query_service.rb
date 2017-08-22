module Hyrax
  module Collections
    module NestedCollectionQueryService
      # @api public
      # @param parent [Collection]
      # @param ability [Ability]
      def self.available_child_collections(parent:, ability:)
        return [] unless parent.try(:nestable?)
        return [] unless ability.can?(:read, parent)
        # Query SOLR for Collections:
        # * Of the same collection_type_gid as the given parent
        # * That the given ability can :edit
        # * Is not the given parent
      end

      # @api public
      # @param child [Collection]
      # @param ability [Ability]
      def self.available_parent_collections(child:, ability:)
        return [] unless child.try(:nestable?)
        return [] unless ability.can?(:edit, child)
        # Query SOLR for Collections:
        # * Of the same collection_type_gid as the given child
        # * That the given ability can :read
        # * Is not the given child
      end

      # @api public
      # @param parent [Collection]
      # @param child [Collection]
      # @return [Boolean] true if the parent can nest the child; false otherwise
      # @todo Consider expanding from same collection type to a lookup table that says "This collection type can have within it, these collection types"
      def self.parent_and_child_can_nest?(parent:, child:)
        return false unless parent.try(:nestable?)
        return false unless child.try(:nestable?)
        return false if parent == child
        parent.collection_type_gid == child.collection_type_gid
      end
    end
  end
end
