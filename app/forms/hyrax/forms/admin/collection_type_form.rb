module Hyrax
  module Forms
    module Admin
      class CollectionTypeForm
        include ActiveModel::Model
        attr_accessor :collection_type
        validates :title, presence: true

        delegate :title, :description, :discoverable, :nestable, :sharable,
                 :require_membership, :allow_multiple_membership, :assigns_workflow,
                 :assigns_visibility, :id, :collection_type_participants, :persisted?, to: :collection_type
      end
    end
  end
end
