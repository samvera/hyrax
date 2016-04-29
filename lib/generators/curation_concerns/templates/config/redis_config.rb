if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # We're in smart spawning mode.
    if forked
      # Re-establish redis connection
      require 'redis'
      config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access

      # The important two lines
      Redis.current.disconnect!
      Redis.current = begin
                        Redis.new(config.merge(thread_safe: true))
                      rescue
                        nil
                      end
    end
  end
else
  config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
  require 'redis'
  Redis.current = begin
             Redis.new(config.merge(thread_safe: true))
           rescue
             nil
           end
end
