# frozen_string_literal: true
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
require 'iiif_manifest'
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
require 'retriable'
require 'valkyrie/indexing_adapter'
require 'valkyrie/indexing/solr/indexing_adapter'
require 'valkyrie/indexing/null_indexing_adapter'

##
# Hyrax is a Ruby on Rails Engine built by the Samvera community. The engine
# provides a foundation for creating many different digital repository
# applications.
#
# @see https://samvera.org Samvera Community
# @see https://guides.rubyonrails.org/engines.html Rails Guides: Getting Started with Engines
module Hyrax
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :Arkivo
    autoload :Collections
    autoload :Configuration
    autoload :ControlledVocabularies
    autoload :EventStore
    autoload :Forms
    autoload :RedisEventStore
    autoload :ResourceSync
    autoload :Zotero
    autoload :Listeners
    autoload :Workflow
    autoload :SimpleSchemaLoader
    autoload :VirusScanner
    autoload :DerivativeBucketedStorage
  end

  ##
  # @return [GlobalID]
  # @see https://github.com/rails/globalid
  def self.GlobalID(input) # rubocop:disable Naming/MethodName
    case input
    when Valkyrie::Resource
      return input.to_global_id if input.respond_to?(:to_global_id)

      ValkyrieGlobalIdProxy.new(resource: input).to_global_id
    else
      input.to_global_id if input.respond_to?(:to_global_id)
    end
  end

  ##
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
    config.logger
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
