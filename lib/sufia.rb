require 'select2-rails'
require 'nest'
require 'mailboxer'
require 'acts_as_follower'
require 'carrierwave'
require "active_resource" # used by FileSet to catch errors & by GeoNamesResource
require 'rails_autolink'
require 'font-awesome-rails'
require 'tinymce-rails'
require 'tinymce-rails-imageupload'
require 'blacklight'
require 'blacklight_advanced_search'
require 'blacklight/gallery'
require 'active_fedora/noid'
require 'hydra/head'
require 'hydra-batch-edit'
require 'hydra-editor'
require 'browse-everything'
require 'curation_concerns'
require 'sufia/engine'
require 'sufia/version'
require 'sufia/inflections'
require 'kaminari_route_prefix'

module Sufia
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :RedisEventStore
    autoload :Arkivo
    autoload :Zotero
  end

  attr_writer :queue

  def self.queue
    @queue ||= config.queue.new('sufia')
  end

  def self.config(&block)
    @config ||= Sufia::Engine::Configuration.new

    yield @config if block

    @config
  end
end
