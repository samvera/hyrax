# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWork`
class GenericWork < Hyrax::Work
  include Hyrax::Schema(:basic_metadata) unless ENV.fetch('HYRAX_FLEXIBLE', false)
  include Hyrax::Schema(:generic_work) unless ENV.fetch('HYRAX_FLEXIBLE', false)
end
