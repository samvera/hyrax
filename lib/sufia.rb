require "sufia/version"
#require 'activerecord-import'
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

module Sufia

  class Engine < ::Rails::Engine
    engine_name 'sufia'
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

module ActiveFedora
  class UnsavedDigitalObject
    def assign_pid
      @pid ||= Sufia::IdService.mint
    end
  end

  class Base
    def stream
      Nest.new(self.class.name, $redis)[to_param]
    rescue
      nil
    end

    def self.stream
      Nest.new(name, $redis)
    rescue
      nil
    end

    def events(size=-1)
      stream[:event].lrange(0, size).map do |event_id|
        {
          action: $redis.hget("events:#{event_id}", "action"),
          timestamp: $redis.hget("events:#{event_id}", "timestamp")
        }
      end
    rescue
      []
    end

    def create_event(action, timestamp)
      event_id = $redis.incr("events:latest_id")
      $redis.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
      event_id
    rescue
      nil
    end

    def log_event(event_id)
      stream[:event].lpush(event_id)
    rescue
      nil
    end
  end
end


ActiveRecord::Base.class_eval do
  def stream
    Nest.new(self.class.name, $redis)[to_param]
  rescue
    nil
  end

  def self.stream
    Nest.new(name, $redis)
  rescue
    nil
  end

  def events(size=-1)
    stream[:event].lrange(0, size).map do |event_id|
      {
        action: $redis.hget("events:#{event_id}", "action"),
        timestamp: $redis.hget("events:#{event_id}", "timestamp")
      }
    end
  rescue
    []
  end

  def profile_events(size=-1)
    stream[:event][:profile].lrange(0, size).map do |event_id|
      {
        action: $redis.hget("events:#{event_id}", "action"),
        timestamp: $redis.hget("events:#{event_id}", "timestamp")
      }
    end
  rescue
    []
  end

  def create_event(action, timestamp)
    event_id = $redis.incr("events:latest_id")
    $redis.hmset("events:#{event_id}", "action", action, "timestamp", timestamp)
    event_id
  rescue
    nil
  end

  def log_event(event_id)
    stream[:event].lpush(event_id)
  rescue
    nil
  end

  def log_profile_event(event_id)
    stream[:event][:profile].lpush(event_id)
  rescue
    nil
  end
end
