# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource Monograph`
class Monograph < Hyrax::Work
  include Hyrax::Schema(:basic_metadata) unless ENV.fetch('HYRAX_FLEXIBLE', false)
  include Hyrax::Schema(:monograph) unless ENV.fetch('HYRAX_FLEXIBLE', false)
end
