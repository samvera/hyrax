require "sufia/models/version"
require "sufia/models/engine"
require 'hydra/head'
require 'devise'
require 'nest'
require 'mailboxer'
require 'acts_as_follower'
require 'paperclip'
require 'RMagick'
require 'activerecord-import'
require 'resque/server'

module Sufia
  extend ActiveSupport::Autoload

  module Models

    extend ActiveSupport::Autoload

    autoload :Resque, 'sufia/models/queue/resque'
    autoload :User, 'sufia/models/user'
  end

  autoload :Resque, 'sufia/models/resque'
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
