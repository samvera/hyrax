Rails.application.config.to_prepare do
  # Register Indexers
  Hyrax::ValkyrieIndexer.register Hyrax::ValkyrieWorkIndexer, as_indexer_for: Hyrax::Work
end
