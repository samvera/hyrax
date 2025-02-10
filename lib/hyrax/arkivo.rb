# frozen_string_literal: true
require 'hyrax/arkivo/config'
require 'hyrax/arkivo/schema_validator'
require 'hyrax/arkivo/metadata_munger'

module Hyrax
  module Arkivo
    VERSION = Hyrax::VERSION

    class SubscriptionError < RuntimeError
    end
  end
end
