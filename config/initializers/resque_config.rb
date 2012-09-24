rails_root = ENV['RAILS_ROOT'] || "#{File.dirname(__FILE__)}/../.."
rails_env = ENV['RAILS_ENV'] || 'development'

config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)['resque'].with_indifferent_access
Resque.redis = Redis.new(host: config[:host], port: config[:port], thread_safe: true)

Resque.inline = rails_env == 'test'
Resque.redis.namespace = "scholarsphere:#{rails_env}"
