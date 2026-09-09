# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Build an indexer module from a schema. Generates custom indexer behavior
  # from rules provided by `index_loader`.
  #
  # @param [Symbol] schema_name
  # @param [#index_rule_for] index_loader
  #
  # @return [Module]
  #
  # @example building a module as a mixin
  #
  #   class MyIndexer < Hyrax::Indexers::ResourceIndexer
  #     include Hyrax::Indexer(:core_metadata)
  #   end
  #
  # @example building a module as a mixin with flexible metadata
  #
  #   class MyIndexer < Hyrax::Indexers::ResourceIndexer
  #     include Hyrax::Indexer(:MyResource, index_loader: M3SchemaLoader.new)
  #   end
  #
  # @since 3.0.0
  def self.Indexer(schema_name, index_loader: SimpleSchemaLoader.new)
    Indexer.new(schema_name: schema_name, index_loader: index_loader)
  end

  ##
  # @api private
  #
  # @see .Indexer
  class Indexer < Module
    attr_accessor :schema_name, :index_loader

    ##
    # @param [Hash{Symbol => Symbol}] rules
    # @param [Symbol] schema_name
    # @param [#index_rule_for] index_loader
    #
    # @return [Module]
    def initialize(rules = nil, schema_name: nil, index_loader: nil)
      super()
      @schema_name = schema_name
      @index_loader = index_loader
      @rules = rules
      # Written from `to_solr`, which runs on request and job threads against one
      # module instance, so this cannot be a plain Hash.
      @authorities = Concurrent::Map.new
      define_solr_method(schema_name:, index_loader:)
    end

    ##
    # @api private
    #
    # Memoized per schema/version/contexts rather than resolved per document:
    # `to_solr` runs once per record in a reindex, and walking the profile there
    # would repeat that work for every one. Mirrors how `@rules` is held.
    def authorities_for(index_loader, schema_args)
      @authorities.compute_if_absent(schema_args) do
        Hyrax::Indexer.authority_rules(index_loader, schema_args)
      end
    end

    def define_solr_method(schema_name:, index_loader:) # rubocop:disable Metrics/MethodLength
      indexer_module = self
      define_method :to_solr do |*args|
        super(*args).tap do |document|
          schema_args = if index_loader.is_a?(Hyrax::M3SchemaLoader)
                          document['schema_version_ssi'] = resource.schema_version
                          document['contexts_ssim'] = resource.contexts
                          { schema: resource.class.name, version: resource.schema_version, contexts: resource.contexts }
                        else
                          { schema: schema_name }
                        end
          rules = @rules || index_loader.index_rules_for(**schema_args)

          authorities = indexer_module.authorities_for(index_loader, schema_args)
          # Memo per attribute, not per index key: a property that is both
          # stored_searchable and facetable has several index keys carrying the
          # same values, and resolving them once each repeats the lookup.
          labels = {}

          rules.each do |index_key, method|
            value = resource.try(method)
            document[index_key] = value

            Hyrax::Indexer.add_label(document, index_key, authorities[method], value,
                                     memo: labels, attribute: method)
          end
        end
      end
    end

    ##
    # @api private
    #
    # Write a controlled property's term labels beside its stored ids, as
    # `<index_key>_label`. The ids are left in place: they are the link target
    # for a URI-valued authority and what OAI harvests.
    #
    # A no-op unless the configured label service can resolve the authority, so
    # an application that registers none indexes exactly as it did before.
    def self.add_label(document, index_key, source, value, memo: {}, attribute: nil)
      return if source.blank?

      label_key = label_key_for(index_key)
      return if label_key.blank?

      # Keyed on the attribute, not the authority: two properties can cite the
      # same vocabulary while holding different values. Holds the resolvable?
      # answer too, so neither call repeats across a property's index keys.
      memo_key = attribute || index_key
      labels = memo.fetch(memo_key) { memo[memo_key] = resolve_labels(source, value) }
      document[label_key] = labels if labels.present?
    rescue StandardError => e
      # Never fail an indexing run over a label; the ids index as-is. Debug
      # rather than warn: this fires per index key per document, so a service
      # that is broken for a whole corpus would otherwise flood the log.
      Hyrax.logger.debug { "Unable to index labels for #{index_key}: #{e.message}" }
    end

    ##
    # @api private
    #
    # nil when the configured service cannot resolve the vocabulary, so the memo
    # holds that answer and `resolvable?` is asked once per attribute.
    def self.resolve_labels(source, value)
      service = Hyrax.config.controlled_vocabulary_label_service
      return unless service.resolvable?(source)

      service.labels_for(source, value)
    end

    ##
    # @api private
    #
    # @see Hyrax::ControlledVocabularyFieldValues.label_key for the derivation
    #   the catalog and presenter read back through.
    def self.label_key_for(index_key)
      key = index_key.to_s
      label_key = Hyrax::ControlledVocabularyFieldValues.label_key(key)
      return if label_key == key

      label_key.to_sym
    end

    ##
    # @api private
    #
    # @return [Hash{Symbol => String}] the controlled authority backing each
    #   attribute. Empty for a custom loader predating
    #   {SchemaLoader#authority_rules_for}, so third-party loaders keep working.
    def self.authority_rules(index_loader, schema_args)
      return {} unless index_loader.respond_to?(:authority_rules_for)

      index_loader.authority_rules_for(**schema_args) || {}
    rescue StandardError => e
      Hyrax.logger.warn("Unable to resolve controlled vocabulary authorities: #{e.message}")
      {}
    end
  end
end
