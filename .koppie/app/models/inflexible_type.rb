# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource InflexibleType`
class InflexibleType < Hyrax::Work
  if Hyrax.config.work_include_metadata?
    include Hyrax::Schema(:core_metadata) unless Hyrax.config.work_default_metadata?
    include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:inflexible_type)
  end
end
