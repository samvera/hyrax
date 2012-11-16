require "sufia/version"
require 'blacklight'
require 'hydra/head'
require 'hydra-ldap' #TODO remove this
require 'hydra-batch-edit'
require 'resque/server'

require 'mailboxer'
require 'acts_as_follower'
require 'paperclip'
require 'will_paginate'
require 'nest'
require 'rmagick'
require 'activerecord-import'

module Sufia

  class Engine < ::Rails::Engine
    engine_name 'sufia'

    initializer "Patch active_fedora" do
      require 'sufia/active_fedora/redis'
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
      current_user.groups.include? 'umg/up.dlt.scholarsphere-admin'
    end
  end

  def self.config(&block)
    @@config ||= Sufia::Engine::Configuration.new

    yield @@config if block

    return @@config
  end

  autoload :Controller,   'sufia/controller'
  autoload :Ldap,         'sufia/ldap'
  autoload :Utils,        'sufia/utils'
  autoload :User,         'sufia/user'
  autoload :ModelMethods, 'sufia/model_methods'
  autoload :Noid,         'sufia/noid'
  autoload :IdService,    'sufia/id_service'
end

