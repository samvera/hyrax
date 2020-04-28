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
require 'hyrax/name'
require 'hyrax/valkyrie_can_can_adapter'
require 'kaminari_route_prefix'

module Hyrax
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :Arkivo
    autoload :Collections
    autoload :Configuration
    autoload :ControlledVocabularies
    autoload :EventStore
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

  ##
  # @return [Logger]
  def self.logger
    @logger ||= Valkyrie.logger
  end

  def self.primary_work_type
    config.curation_concerns.first
  end

  ##
  # @return [Valkyrie::IndexingAdapter]
  def self.index_adapter
    config.index_adapter
  end

  ##
  # @return [Dry::Events::Publisher]
  def self.publisher
    config.publisher
  end

  ##
  # The Valkyrie persister used for PCDM models throughout Hyrax
  #
  # @note always use this method to retrieve the persister when data
  #   interoperability with Hyrax is required
  def self.persister
    metadata_adapter.persister
  end

  ##
  # The Valkyrie metadata adapter used for PCDM models throughout Hyrax
  #
  # @note always use this method to retrieve the metadata adapter when data
  #   interoperability with Hyrax is required
  def self.metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  ##
  # The Valkyrie storage_adapter used for PCDM files throughout Hyrax
  #
  # @note always use this method to retrieve the storage adapter when handling
  #   files that will be used by Hyrax
  def self.storage_adapter
    Valkyrie.config.storage_adapter
  end

  ##
  # The Valkyrie query service used for PCDM files throughout Hyrax
  #
  # @note always use this method to retrieve the query service when data
  #   interoperability with Hyrax is required
  def self.query_service
    metadata_adapter.query_service
  end

  ##
  # The custom queries common to Hyrax
  def self.custom_queries
    query_service.custom_queries
  end
end
