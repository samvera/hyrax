# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads 1, threads_count - 2

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
#
rails_env = ENV.fetch("RAILS_ENV", 'development')
environment rails_env

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE", 'tmp/pids/server.pid')

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch('WEB_CONCURRENCY', 1)

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Embedded Sidekiq https://github.com/sidekiq/sidekiq/wiki/Embedding
if ENV.fetch('SIDEKIQ_MODE', false) == 'embed'
  embedded_sidekiq = nil

  on_worker_boot do
    embedded_sidekiq = Sidekiq.configure_embed do |config|
      config.logger.level = ENV.fetch("RAILS_LOG_LEVEL", 'debug')
      config.queues = %w[ingest batch default]
      config.concurrency = ENV.fetch('SIDEKIQ_WORKERS', 2) # Adjust max `threads` above accordingly
    end
    embedded_sidekiq.run
  end

  on_worker_shutdown do
    embedded_sidekiq&.stop
  end
end