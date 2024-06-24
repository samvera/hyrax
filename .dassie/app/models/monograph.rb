# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource Monograph`
class Monograph < Hyrax::Work
  include Hyrax::Schema(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::Schema(:monograph) unless Hyrax.config.flexible?
end
