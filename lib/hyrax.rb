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
require 'hyrax/deprecation'
require 'hyrax/inflections'
require 'hyrax/name'
require 'hyrax/valkyrie_can_can_adapter'
require 'retriable'
require 'valkyrie/indexing_adapter'
require 'valkyrie/indexing/solr/indexing_adapter'
require 'valkyrie/indexing/redis_queue/indexing_adapter'
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
    autoload :SchemaLoader
    autoload :M3SchemaLoader
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

  ##
  # Returns the schema for a resource class, optionally scoped by admin set contexts.
  #
  # When +admin_set_id+ is present and flexible schema is enabled, the admin set's
  # contexts are used so flexible resources get a context-aware schema. If the
  # admin set is not found, falls back to the base schema without raising.
  #
  # @param klass [Class] a Valkyrie resource class (e.g. Hyrax::Work)
  # @param admin_set_id [String, nil] optional admin set id to resolve contexts from
  # @return [Dry::Types::Schema, Array] the schema (keys/types or enumerable of keys)
  def self.schema_for(klass:, admin_set_id: nil)
    contexts = if admin_set_id.blank? || !config.flexible?
                 []
               else
                 schema_contexts_for(admin_set_id)
               end
    resolve_schema(klass, contexts)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    fallback_schema(klass)
  end

  ##
  # @api private
  #
  # @param admin_set_id [String]
  # @return [Array<String>] context identifiers from the admin set, or []
  def self.schema_contexts_for(admin_set_id)
    return [] if admin_set_id.blank?
    admin_set = query_service.find_by(id: admin_set_id)
    admin_set.respond_to?(:contexts) ? Array(admin_set.contexts) : []
  end
  private_class_method :schema_contexts_for

  ##
  # @api private
  #
  # @param klass [Class]
  # @param contexts [Array<String>]
  # @return [Dry::Types::Schema, Array] the resolved schema for the class and contexts
  def self.resolve_schema(klass, contexts)
    if contexts.present? && klass.respond_to?(:flexible?) && klass.flexible?
      klass.new(contexts: contexts).singleton_class.schema || klass.schema
    else
      klass.new.singleton_class.schema || klass.schema
    end
  end
  private_class_method :resolve_schema

  ##
  # @api private
  #
  # @param klass [Class]
  # @return [Dry::Types::Schema, Array] the base schema when admin set lookup fails
  def self.fallback_schema(klass)
    klass.new.singleton_class.schema || klass.schema
  end
  private_class_method :fallback_schema
end
