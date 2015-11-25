module Sufia
  module Arkivo
    def self.config
      @config ||= YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'arkivo.yml'))).result).with_indifferent_access[Rails.env]
    end

    def self.new_subscription_url
      '/api/subscription'
    end
  end
end
