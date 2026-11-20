# frozen_string_literal: true

module Hyrax
  ##
  # Resolves controlled vocabulary term ids to labels using the local
  # Questioning Authority vocabularies an application has configured in
  # `config/authorities/`.
  #
  # Not installed by default — Hyrax ships
  # {Hyrax::ControlledVocabularyLabelService}, which resolves nothing. Register
  # this to have labels indexed and displayed:
  #
  # @example config/initializers/hyrax.rb
  #   Hyrax.config.controlled_vocabulary_label_service =
  #     Hyrax::QaControlledVocabularyLabelService.new
  #
  # A property's `controlled_values.sources` entry is matched to a local
  # subauthority of the same name, so a property citing `licenses` resolves
  # against `config/authorities/licenses.yml`.
  #
  # Reindex after registering: the show page and catalog read the label fields
  # the indexer writes, so an existing corpus keeps displaying ids until it is
  # reindexed.
  class QaControlledVocabularyLabelService < ControlledVocabularyLabelService
    CACHE_KEY_PREFIX = 'hyrax_controlled_vocabulary_labels-v1-'
    CACHE_EXPIRATION = 1.hour

    ##
    # @param source [String] a controlled vocabulary name
    # @return [Boolean] whether a local authority of that name exists. Remote
    #   authorities are excluded structurally — Qa's registry only holds locally
    #   registered subauthorities — so resolving one never costs a request.
    def resolvable?(source)
      name = source.to_s.strip
      return false if name.empty?

      local_authority_names.include?(name)
    end

    ##
    # @param source [String] a controlled vocabulary name
    # @param values [Array, Object, nil] the stored term ids
    # @return [Array] one entry per value, in the order given, falling back to
    #   the value itself where the authority does not know it
    def labels_for(source, values)
      values = Array.wrap(values)
      return values if values.empty?

      name = source.to_s.strip
      # Checked before the cache rather than only inside the map builder:
      # Rails.cache outlives the authority's availability, so a map cached while
      # a vocabulary existed would otherwise keep answering after it is gone.
      return values unless resolvable?(name)

      map = label_map(name)
      return values if map.empty?

      values.map { |value| map.fetch(value.to_s, value) }
    end

    private

    # Assigned inside the rescue as well: Qa raises rather than memoizing when
    # an application has no config/authorities, so a bare `||=` would pay a
    # raised-and-caught exception on every call.
    def local_authority_names
      @local_authority_names ||= Qa::Authorities::Local.subauthorities.map(&:to_s)
    rescue StandardError => e
      Hyrax.logger.debug { "No local authorities available: #{e.message}" }
      @local_authority_names = [].freeze
    end

    # Held in-process as well as in Rails.cache, so a reindex builds each map
    # once per process however short the cache expiry is.
    def label_map(name)
      @label_maps ||= {}
      @label_maps.fetch(name) do
        @label_maps[name] = Rails.cache.fetch(cache_key(name), expires_in: CACHE_EXPIRATION) do
          build_label_map(name)
        end
      end
    end

    # One map per authority rather than a lookup per value: a file-based
    # authority re-reads and re-parses its yaml on every call, so resolving id
    # by id costs a parse per value per document during a reindex.
    #
    # `#all` is what both backends normalize through — a file-based authority's
    # `term:` is emitted as `label:`, and a table-based one emits `label:`
    # natively. The `term` reads cover a plain-Hash double.
    def build_label_map(name)
      return {} unless resolvable?(name)

      Qa::Authorities::Local.subauthority_for(name).all.each_with_object({}) do |term, map|
        id = term[:id] || term['id']
        next if id.blank?

        label = term[:label] || term['label'] || term[:term] || term['term']
        map[id.to_s] = label.presence || id.to_s
      end
    rescue StandardError => e
      # A missing or broken authority must not fail an indexing run.
      Hyrax.logger.warn("Unable to load labels for controlled vocabulary #{name}: #{e.message}")
      {}
    end

    def cache_key(name)
      "#{CACHE_KEY_PREFIX}#{name}"
    end
  end
end
