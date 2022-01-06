# frozen_string_literal: true
module Hyrax
  module Analytics
    ##
    # a completely empty module to include if no parser is configured
    module NullAnalyticsParser; end

    def self.provider_parser
      "Hyrax::Analytics::#{Hyrax.config.analytics_provider.to_s.capitalize}".constantize
    rescue NameError => err
      Hyrax.logger.warn("Couldn't find an Analytics provider matching "\
                        " #{Hyrax.config.analytics_provider}. Loading " \
                        " NullAnalyticsProvider.\n#{err.message}")
      NullAnalyticsParser
    end

    include provider_parser
  end
end
