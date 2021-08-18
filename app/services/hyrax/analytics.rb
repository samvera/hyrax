# frozen_string_literal: true
module Hyrax
  module Analytics
    def self.provider_parser
      "Hyrax::Analytics::#{Hyrax.config.analytics_provider.to_s.capitalize}"
    end
    include provider_parser.constantize
  end
end
