config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
$redis = Redis.new(host: config[:host], port: config[:port]) rescue nil

# Code borrowed from Obie's Redis patterns talk at RailsConf'12
Nest.class_eval do
  def initialize(key, redis=$redis)
    super(key.to_param)
    @redis = redis
  end

  def [](key)
    self.class.new("#{self}:#{key.to_param}", @redis)
  end
end
