# Reads and sets up config for the analytics platform
# Needs to run after other initializers
Rails.application.config.after_initialize do
  case Hyrax.config.analytics
  when 'matomo'
    require 'piwik'
    filename = Rails.root.join('config', 'analytics.yml')
    yaml = YAML.safe_load(File.read(filename))
    unless yaml
      Rails.logger.error("Unable to fetch any keys from #{filename}.")
      return
    end
    config = yaml.fetch('analytics')
    Piwik::PIWIK_URL = config['matomo_url']
    Piwik::PIWIK_TOKEN = config['matomo_token']

    Hyrax::Analytics::Matomo.config = config
    unless Hyrax::Analytics::Matomo.valid?
      Rails.logger.error("Invalid Matomo config from #{filename}.")
    end

  when 'google' # rubocop:disable Lint/EmptyWhen
    # TODO: move/refactor google yaml config to here
  end
end
