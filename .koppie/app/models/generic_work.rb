# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWork`
class GenericWork < Hyrax::Work
  include Hyrax::Schema(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::Schema(:generic_work) unless Hyrax.config.flexible?
end
