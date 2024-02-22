# frozen_string_literal: true

ActiveSupport::Reloader.to_prepare do
  Hydra::Derivatives.config.output_file_service = Hyrax::ValkyriePersistDerivatives
  Hydra::Derivatives.config.source_file_service = Hyrax::LocalFileService
end
