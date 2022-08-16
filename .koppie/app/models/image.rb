# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource Image`
class Image < Hyrax::Work
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema(:image)
end
