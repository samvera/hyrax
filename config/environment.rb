# Load the rails application
require File.expand_path('../application', __FILE__)

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # We're in smart spawning mode.
    if forked
      # Re-establish redis connection
      require 'redis'
      config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access

      # The important two lines
      $redis.client.disconnect if $redis 
      $redis = Redis.new(host: config[:host], port: config[:port], thread_safe: true) rescue nil
      Resque.redis.client.reconnect if Resque.redis
    end
  end
else
  config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
  $redis = Redis.new(host: config[:host], port: config[:port], thread_safe: true) rescue nil
end

class Logger
  def format_message(severity, timestamp, progname, msg)
    "#{timestamp} (#{$$}) #{msg}\n"
  end
end

# Initialize the rails application
ScholarSphere::Application.initialize!
ActiveRecord::Base.connection.execute("SET AUTOCOMMIT=1") if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) and (ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::Mysql2Adapter)
