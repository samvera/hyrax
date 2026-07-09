# frozen_string_literal: true

Rails.application.config.after_initialize do
  unless Valkyrie::StorageAdapter.storage_adapters.key?(:branding_disk)
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Disk.new(base_path: Hyrax.config.branding_path,
                                  path_generator: Hyrax::ValkyrieSimplePathGenerator),
      :branding_disk
    )
  end

  unless Valkyrie::StorageAdapter.storage_adapters.key?(:derivatives_disk)
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Disk.new(base_path: Hyrax.config.derivatives_path, path_generator: Hyrax::DerivativeBucketedStorage),
      :derivatives_disk
    )
  end
end
