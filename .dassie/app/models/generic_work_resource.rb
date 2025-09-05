# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
class GenericWorkResource < Hyrax::Work
  if Hyrax.config.work_include_metadata?
    include Hyrax::Schema(:core_metadata)
    include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:generic_work_resource)
  end

  Hyrax::ValkyrieLazyMigration.migrating(self, from: GenericWork) if Hyrax.config.valkyrie_transition?
end
