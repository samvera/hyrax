require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dassie
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
    config.add_autoload_paths_to_load_path = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # use SideKiq by default
    config.active_job.queue_adapter = :sidekiq
    # inline can be useful when debugging
    # config.active_job.queue_adapter = :inline

    ##
    # When using the Goddess adapter of Hyrax 5.x, we want to have a
    # canonical answer for what are the Work Types that we want to manage.
    #
    # We don't want to rely on `Hyrax.config.curation_concerns`, as these are
    # the ActiveFedora implementations.
    #
    # @return [Array<Class>]
    def self.work_types
      Hyrax.config.curation_concerns.map do |cc|
        if cc.to_s.end_with?("Resource")
          cc
        else
          # We may encounter a case where we don't have an old ActiveFedora
          # model that we're mapping to.  For example, let's say we add Game as
          # a curation concern.  And Game has only ever been written/modeled via
          # Valkyrie.  We don't want to also have a GameResource.
          "#{cc}Resource".safe_constantize || cc
        end
      end
    end
  end
end
