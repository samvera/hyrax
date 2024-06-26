# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceForm < Hyrax::Forms::PcdmCollectionForm
  include Hyrax::FormFields(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::FormFields(:collection_resource) unless Hyrax.config.flexible?
end
