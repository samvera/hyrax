# frozen_string_literal: true

# This is necessary to force the indexers to register themselves properly
Rails.application.config.to_prepare do
  Hyrax::ValkyrieWorkIndexer
  # Namespace::YourWorkIndexer
end