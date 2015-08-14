if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # We're in smart spawning mode.
    if forked
      # Re-establish redis connection
      require 'redis'
      config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access

      # The important two lines
      $redis.client.disconnect if $redis
      $redis = begin
                 Redis.new(host: config[:host], port: config[:port], thread_safe: true)
               rescue
                 nil
               end
      Resque.redis = $redis
      Resque.redis.namespace = "#{CurationConcerns.config.redis_namespace}:#{Rails.env}"
      Resque.redis.client.reconnect if Resque.redis
    end
  end
else
  config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
  $redis = begin
             Redis.new(host: config[:host], port: config[:port], thread_safe: true)
           rescue
             nil
           end
end

# Code borrowed from Obie's Redis patterns talk at RailsConf'12
Nest.class_eval do
  def initialize(key, redis = $redis)
    super(key.to_param)
    @redis = redis
  end

  def [](key)
    self.class.new("#{self}:#{key.to_param}", @redis)
  end
end
