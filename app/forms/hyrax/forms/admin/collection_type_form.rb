module Hyrax
  module Forms
    module Admin
      class CollectionTypeForm
        include ActiveModel::Model
<<<<<<< HEAD

        # create enough of the form to make the views happy for now
        def title
          'placeholder'
        end
=======
        attr_accessor :collection_type
        validates :title, presence: true

        delegate :title, :description, :discoverable, :nestable, :sharable,
                 :require_membership, :allow_multiple_membership, :assigns_workflow,
                 :assigns_visibility, :id, :collection_type_participants, :persisted?, to: :collection_type
>>>>>>> d12ade881334676075d4495cbbb6c22b39c665ec
      end
    end
  end
end
