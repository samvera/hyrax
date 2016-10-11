require 'select2-rails'
require 'nest'
require 'redis-namespace'
require 'mailboxer'
require 'carrierwave'
require 'rails_autolink'
require 'font-awesome-rails'
require 'tinymce-rails'
require 'tinymce-rails-imageupload'
require 'blacklight'
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
    autoload :Arkivo
    autoload :Configuration
    autoload :RedisEventStore
    autoload :ResourceSync
    autoload :Zotero
  end

  def self.config(&block)
    @config ||= Sufia::Configuration.new

    yield @config if block

    @config
  end

  def self.primary_work_type
    CurationConcerns::WorkRelation::DummyModel.primary_concern
  end
end
