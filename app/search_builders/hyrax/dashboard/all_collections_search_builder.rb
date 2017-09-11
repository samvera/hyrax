module Hyrax
  module Dashboard
    class AllCollectionsSearchBuilder < Hyrax::CollectionSearchBuilder
      # This overrides the models in FilterByType
      def models
        [::AdminSet, ::Collection]
      end
    end
  end
end
