require "scholarsphere/version"
require 'blacklight'
require 'hydra'
require 'hydra-batch-edit'
require 'resque/server'

require 'mailboxer'
require 'acts_as_follower'
require 'paperclip'
require 'will_paginate'

module Scholarsphere

  class Engine < ::Rails::Engine
    engine_name 'scholarsphere'
  end

  class ResqueAdmin
    def self.matches?(request)
      current_user = request.env['warden'].user
      return false if current_user.blank?
      # TODO code a group here that makes sense
      current_user.groups.include? 'umg/up.dlt.scholarsphere-admin'
    end
  end

  autoload :Controller,   'scholarsphere/controller'
  autoload :Ldap,         'scholarsphere/ldap'
  autoload :Utils,        'scholarsphere/utils'
  autoload :User,         'scholarsphere/user'
  autoload :ModelMethods, 'scholarsphere/model_methods'
  autoload :Noid,         'scholarsphere/noid'
end
