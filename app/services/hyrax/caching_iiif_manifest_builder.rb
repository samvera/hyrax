# frozen_string_literal: true

module Hyrax
  ##
  # constructs IIIF Manifests and holds them in the Rails cache,
  # this approach avoids long manifest build times for some kinds of requests,
  # at the cost of introducing cache invalidation issues.
  class CachingIiifManifestBuilder < ManifestBuilderService
    KEY_PREFIX = 'iiif-cache-v1'

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
      # @note adding a version_for suffix helps us manage cache expiration,
      #   reducing false cache hits
      #
      # @param presenter [Hyrax::IiifManifestPresenter]
      #
      # @return [String]
      def manifest_cache_key(presenter:)
        "#{KEY_PREFIX}_#{presenter.id}/#{version_for(presenter)}"
      end

      ##
      # @return [String]
      def version_for(presenter)
        presenter.version
      end
  end
end
