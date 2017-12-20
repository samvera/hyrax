require 'select2-rails'
require 'nest'
require 'redis-namespace'
require 'mailboxer'
require 'carrierwave'
require 'rails_autolink'
require 'font-awesome-rails'
require 'tinymce-rails'
require 'blacklight'
require 'blacklight/gallery'
require 'noid-rails'
require 'hydra/head'
require 'hydra-editor'
require 'browse-everything'
require 'hydra/works'
require 'hyrax/engine'
require 'hyrax/version'
require 'hyrax/inflections'
require 'kaminari_route_prefix'

module Hyrax
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :Arkivo
    autoload :Collections
    autoload :Configuration
    autoload :ControlledVocabularies
    autoload :RedisEventStore
    autoload :ResourceSync
    autoload :Zotero
  end

  # @api public
  #
  # Exposes the Hyrax configuration
  #
  # @yield [Hyrax::Configuration] if a block is passed
  # @return [Hyrax::Configuration]
  # @see Hyrax::Configuration for configuration options
  def self.config(&block)
    @config ||= Hyrax::Configuration.new

    yield @config if block

    @config
  end

  def self.primary_work_type
    Hyrax::WorkRelation::DummyModel.primary_concern
  end
end
