# frozen_string_literal: true

Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::Disk.new(base_path: Hyrax.config.branding_path,
                              path_generator: Hyrax::ValkyrieSimplePathGenerator),
  :branding_disk
)
