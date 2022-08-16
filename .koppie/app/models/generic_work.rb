# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWork`
class GenericWork < Hyrax::Work
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema(:generic_work)
end
