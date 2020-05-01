# frozen_string_literal: true

module Hyrax
  ##
  # constructs IIIF Manifests and holds them in the Rails cache,
  # this approach avoids long manifest build times for some kinds of requests,
  # at the cost of introducing cache invalidation issues.
  class CachingIiifManifestBuilder < ManifestBuilderService
    attr_accessor :expires_in

    ##
    # @api public
    #
    # @param iiif_manifest_factory [Class] a class that initializes with presenter
    #        object and returns an object that responds to `#to_h`
    # @param expires_in [Integer] the number of seconds until the cache expires
    # @see Hyrax::Configuration#iiif_manifest_cache_duration
    def initialize(iiif_manifest_factory: ::IIIFManifest::ManifestFactory, expires_in: Hyrax.config.iiif_manifest_cache_duration)
      self.expires_in = expires_in

      super(iiif_manifest_factory: iiif_manifest_factory)
    end

    ##
    # @see ManifestBuilderService#as_json
    def manifest_for(presenter:)
      Rails.cache.fetch(manifest_cache_key(presenter: presenter), expires_in: expires_in) do
        super
      end
    end

    private

      ##
      # By adding the Solr '_version_' field to the cache key, we shouldn't
      # run into the problem of fetching an outdated version of the manifest.
      # @param presenter [Hyrax::WorkShowPresenter]
      #
      # @return [String]
      def manifest_cache_key(presenter:)
        "#{presenter.id}/#{presenter.solr_document['_version_']}"
      end
  end
end
