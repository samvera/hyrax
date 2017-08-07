module Hyrax
  module Forms
    module Admin
      class CollectionTypeForm
        include ActiveModel::Model

        # create enough of the form to make the views happy for now
        def title
          'placeholder'
        end
      end
    end
  end
end
