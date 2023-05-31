# frozen_string_literal: true
require 'redis'
require 'connection_pool'
config = YAML.safe_load(ERB.new(IO.read(Rails.root.join('config', 'redis.yml'))).result)[Rails.env].with_indifferent_access

size = ENV.fetch("HYRAX_REDIS_POOL_SIZE", 5)
timeout = ENV.fetch("HYRAX_REDIS_TIMEOUT", 5)

Hyrax.config.redis_connection =
  ConnectionPool::Wrapper.new(size: size, timeout: timeout) { Redis.new(config) }
