# frozen_string_literal: true
#
Rails.application.reloader.to_prepare do
  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Hyrax.config.branding_path,
                                path_generator: Hyrax::ValkyrieSimplePathGenerator),
    :branding_disk
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Hyrax.config.derivatives_path, path_generator: Hyrax::DerivativeBucketedStorage),
    :derivatives_disk
  )
end
