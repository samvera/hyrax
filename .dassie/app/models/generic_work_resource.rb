# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
class GenericWorkResource < Hyrax::Work
  include Hyrax::Schema(:basic_metadata) unless ENV.fetch('HYRAX_FLEXIBLE', false)
  include Hyrax::Schema(:generic_work_resource) unless ENV.fetch('HYRAX_FLEXIBLE', false)

  Hyrax::ValkyrieLazyMigration.migrating(self, from: GenericWork)
end
