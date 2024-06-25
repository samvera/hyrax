# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
class GenericWorkResource < Hyrax::Work
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema(:generic_work_resource)

  Hyrax::ValkyrieLazyMigration.migrating(self, from: GenericWork) if Hyrax.config.valkyrie_transition?
end
