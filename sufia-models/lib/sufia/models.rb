require "sufia/models/version"
require "sufia/models/engine"
require 'hydra/head'
require 'nest'
require 'mailboxer'
require 'acts_as_follower'
require 'paperclip'
require "active_resource" # used by GenericFile to catch errors & by GeoNamesResource
begin
  # activerecord-import 0.3.1 does not support rails 4, so we don't require it.
  require 'activerecord-import'
rescue LoadError
  $stderr.puts "Sufia-models is unable to load activerecord-import"
end
require 'resque/server'

module Sufia
  extend ActiveSupport::Autoload

  module Models
  end

  autoload :Utils, 'sufia/models/utils'

  attr_writer :queue

  def self.queue
    @queue ||= config.queue.new('sufia')
  end

  def self.config(&block)
    @@config ||= Sufia::Models::Engine::Configuration.new

    yield @@config if block

    return @@config
  end
end
