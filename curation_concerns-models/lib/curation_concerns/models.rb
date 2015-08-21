require 'curation_concerns/models/version'
require 'curation_concerns/models/engine'

require 'hydra/head'
require 'nest'
# require "active_resource" # used by GenericFile to catch errors & by GeoNamesResource
require 'resque/server'

module CurationConcerns
  extend ActiveSupport::Autoload

  module Models
  end

  autoload :Utils, 'curation_concerns/models/utils'
  autoload :Permissions
  autoload :Messages

  attr_writer :queue

  def self.queue
    @queue ||= config.queue.new('curation_concerns')
  end

  def self.config(&block)
    @@config ||= CurationConcerns::Models::Engine::Configuration.new

    yield @@config if block

    @@config
  end
end
