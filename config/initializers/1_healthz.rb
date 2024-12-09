# frozen_string_literal: true

# Add an endpoint at `/healthz` if `OkComputer` is installed.
#   - `healthz` functions as a basic liveness check;
#   - `healthz/{status_name}` checks a specific registered status;
#   - `healthz/all` compiles all registered checks.
#
# To install these checks by default, add `gem 'okcomputer'` to your
# application's `Gemfile`.
#
# @see https://github.com/sportngin/okcomputer/

Rails.application.reloader.to_prepare do
  OkComputer.mount_at = 'healthz'

  require 'hyrax/health_checks'

  OkComputer::Registry.register 'solr', Hyrax::HealthChecks::SolrCheck.new
  OkComputer::Registry.register 'migrations', OkComputer::ActiveRecordMigrationsCheck.new

  # check cache
  if ENV['MEMCACHED_HOST']
    OkComputer::Registry
      .register 'cache', OkComputer::CacheCheck.new(ENV.fetch('MEMCACHED_HOST'))
  else
    OkComputer::Registry.register 'cache', OkComputer::CacheCheck.new
  end
rescue NameError => err
  raise(err) unless err.message.include?('OkComputer')

  Hyrax.logger.info 'OkComputer not installed. ' \
                    'Skipping health endpoint at `/healthz`. ' \
                    'Add `gem "OkComputer"` to your Gemfile if you want to ' \
                    'install default health checks.'
end
