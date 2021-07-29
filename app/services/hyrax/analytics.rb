# frozen_string_literal: true

module Hyrax
  module Analytics
    def self.provider_parser
      "Hyrax::Analytics::#{Hyrax.config.analytics_provider.to_s.capitalize}"
    end
    include provider_parser.constantize

    # all of the methods below would actually have their logic in
    # the provider parser.
    def type
      # work or collection class
    end

    def source_id
      # work or collection id
    end

    def title
      # work of collection title
    end

    def views
      # hash of views
      {
        daily: [today, yesterday, 2.days_ago, etc], # for 31 days
        monthly: [this_month, last_month, etc], # for 12 months
        all: alltime_views # single number
      }
    end

    def downloads
      # hash of downloads
      {
        daily: [today, yesterday, 2.days_ago, etc], # for 31 days
        monthly: [this_month, last_month, etc], # for 12 months
        all: alltime_downloads # single number
      }
    end
  end
end
