# frozen_string_literal: true

class AdminSetResource < Hyrax::AdministrativeSet
  include Hyrax::ArResource
  include Hyrax::Permissions::Readable
  Hyrax::ValkyrieLazyMigration.migrating(self, from: ::AdminSet) if Hyrax.config.valkyrie_transition?

  # include WithPermissionTemplateShim
end