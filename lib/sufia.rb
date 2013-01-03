require "sufia/version"
require 'blacklight'
require 'blacklight_advanced_search'
require 'hydra/head'
require 'hydra-batch-edit'
require 'resque/server'

require 'mailboxer'
require 'acts_as_follower'
require 'paperclip'
require 'will_paginate'
require 'nest'
require 'RMagick'
require 'activerecord-import'
require 'rails_autolink'

autoload :Zip, 'zipruby'
module Sufia
  extend ActiveSupport::Autoload

  autoload :Resque, 'sufia/queue/resque'

  attr_accessor :queue

  class Engine < ::Rails::Engine
    engine_name 'sufia'

    config.queue = Sufia::Resque::Queue
    config.ffmpeg_path = 'ffmpeg'
    config.fits_message_length = 5
    

    config.autoload_paths << File.expand_path("../sufia/jobs", __FILE__)
    
    initializer "Patch active_fedora" do
      require 'sufia/active_fedora/redis'
    end

    initializer "Patch kaminari" do
      require "kaminari/helpers/tag"
    end

    initializer "Patch active_record" do
      require 'sufia/active_record/redis'
    end

  end

  class ResqueAdmin
    def self.matches?(request)
      current_user = request.env['warden'].user
      return false if current_user.blank?
      # TODO code a group here that makes sense
      #current_user.groups.include? 'umg/up.dlt.scholarsphere-admin'
    end
  end

  def self.config(&block)
    @@config ||= Sufia::Engine::Configuration.new

    yield @@config if block

    return @@config
  end

  def self.queue
    @queue ||= config.queue.new('sufia')
  end

  autoload :GenericFile
  autoload :Controller
  autoload :Utils
  autoload :User
  autoload :ModelMethods
  autoload :Noid
  autoload :IdService
  autoload :HttpHeaderAuth
  autoload :SolrDocumentBehavior
  autoload :FilesControllerBehavior
  autoload :DownloadsControllerBehavior
end

