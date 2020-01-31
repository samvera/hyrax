# frozen_string_literal: true

module Hyrax
  ##
  # Indexes Hyrax::Work objects
  class ValkyrieWorkIndexer < Hyrax::ValkyrieIndexer
    # Registration needs to happen for each object that is generated through the system
    Hyrax::ValkyrieIndexer.register self, as_indexer_for: Hyrax::Work

    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer
    include Hyrax::Indexer(:core_metadata)
    include Hyrax::Indexer(:basic_metadata)
  end
end
