# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceForm < Hyrax::Forms::PcdmCollectionForm
  if Hyrax.config.collection_include_metadata?
    include Hyrax::FormFields(:basic_metadata)
    include Hyrax::FormFields(:collection_resource)
  end
  check_if_flexible(CollectionResource)
end
