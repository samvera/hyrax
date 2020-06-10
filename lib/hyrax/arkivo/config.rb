# frozen_string_literal: true
module Hyrax
  module Arkivo
    def self.config
      @config ||= YAML.safe_load(ERB.new(IO.read(Rails.root.join('config', 'arkivo.yml'))).result).with_indifferent_access[Rails.env]
    end

    def self.new_subscription_url
      '/api/subscription'
    end
  end
end
