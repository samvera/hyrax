module Hyrax
  module Forms
    module Dashboard
      # Responsible for validating that both the parent and child are valid for nesting; If so, then
      # also responsible for persisting those changes.
      class NestCollectionForm
        include ActiveModel::Model

        def initialize(parent: nil, child: nil)
          self.parent = parent
          self.child = child
        end

        attr_accessor :parent, :child

        validates :parent, presence: true
        validates :child, presence: true

        def save
          return false unless valid?
          persist!
        end

        def save!
          raise unless valid?
          persist!
        end

        def available_child_collections
          return [] if parent.blank?
        end

        def available_parent_collections
          return [] if child.blank?
        end

        private

          def persist!
            true
          end
      end
    end
  end
end
