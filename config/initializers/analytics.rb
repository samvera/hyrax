# Reads and sets up config for the analytics platform
# Needs to run after other initializers
Rails.application.config.after_initialize do
  filename = Rails.root.join('config', 'analytics.yml')
  next unless File.exist?(filename)
  yaml = YAML.safe_load(File.read(filename))
  unless yaml
    Rails.logger.error("Unable to fetch any keys from #{filename}.")
    next
  end
  config = yaml.fetch('analytics')

  case Hyrax.config.analytics
  when 'matomo'
    require 'piwik'
    Piwik::PIWIK_URL = config['matomo_url']
    Piwik::PIWIK_TOKEN = config['matomo_token']

    Hyrax::Analytics::Matomo.config = config
    Rails.logger.error("Invalid Matomo config from #{filename}.") unless Hyrax::Analytics::Matomo.valid?
  when 'google' || true
    Hyrax::Analytics::GoogleAnalytics.config = config
    Rails.logger.error("Invalid Google Analytics config from #{filename}.") unless Hyrax::Analytics::GoogleAnalytics.valid?
  end
end
