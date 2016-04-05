require 'resque/pool/tasks'

# This provides access to the Rails env within all Resque workers
task 'resque:setup' => :environment

# Set up resque-pool
task 'resque:pool:setup' do
  ActiveRecord::Base.connection.disconnect!
  require 'resque/pool'
  Resque::Pool.after_prefork do |job|
    ActiveRecord::Base.establish_connection
    Resque.redis.client.reconnect
  end
end
