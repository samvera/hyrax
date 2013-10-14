require "sufia/models/version"
require "sufia/models/engine"
require 'hydra/head'
require 'nest'
require 'mailboxer'
require 'acts_as_follower'
require 'paperclip'
require "active_resource" # used by GenericFile to catch errors & by GeoNamesResource
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
