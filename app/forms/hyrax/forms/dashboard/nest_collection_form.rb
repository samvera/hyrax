module Hyrax
  module Forms
    module Dashboard
      # Responsible for validating that both the parent and child are valid for nesting; If so, then
      # also responsible for persisting those changes.
      class NestCollectionForm
        include ActiveModel::Model

        # @param [Hyrax::Colection, NilClass] parent
        # @param [Hyrax::Colection, NilClass] child
        # @param [Object] query_service
        def initialize(parent: nil, child: nil, query_service: default_query_service)
          self.parent = parent
          self.child = child
          self.query_service = query_service
        end

        attr_accessor :parent, :child

        validates :parent, presence: true
        validates :child, presence: true
        validate :parent_and_child_can_be_nested

        def save
          return false unless valid?
          persist!
        end

        def save!
          raise unless valid?
          persist!
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

          attr_accessor :query_service

          def default_query_service
            raise 'TODO'
          end

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

          # Write the appropriate relationship.
          def persist!
            true
          end
      end
    end
  end
end
