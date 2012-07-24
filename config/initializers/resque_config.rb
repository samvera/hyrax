rails_root = ENV['RAILS_ROOT'] || "#{File.dirname(__FILE__)}/../.."
rails_env = ENV['RAILS_ENV'] || 'development'

Resque.inline = rails_env == 'test'
Resque.redis.namespace = "scholarsphere:#{rails_env}"
