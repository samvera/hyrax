# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
class GenericWorkResource < Hyrax::Work
  include Hyrax::Schema(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::Schema(:generic_work_resource) unless Hyrax.config.flexible?

  Hyrax::ValkyrieLazyMigration.migrating(self, from: GenericWork) if Hyrax.config.valkyrie_transition?
end
