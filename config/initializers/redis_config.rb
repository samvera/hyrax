config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
$redis = Redis.new(:host => config[:host], :port => config[:port])
