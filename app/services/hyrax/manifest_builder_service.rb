require 'iiif_manifest'

module Hyrax
  # A class responsible for converting a Hyrax::Work like thing into a IIIF
  # manifest.
  #
  # @see !{.as_json}
  class ManifestBuilderService
    # @api public
    #
    # @param presenter [Hyrax::WorkShowPresenter] the work presenter from which
    #        we'll build a manifest.
    # @param iiif_manifest_factory [Class] a class that initializes with presenter
    #        object and returns an object that responds to `#to_h`
    # @param expires_in [Integer] the number of seconds until the cache expires
    # @param cache_manifest [Boolean] should we perform Rails level caching of
    #        the generated manifest
    #
    # @note While the :presenter may be a Hyrax::WorkShowPresenter it is likely
    #       defined by Hyrax::WorksControllerBehavior.show_presenter
    #
    # @note Why the public class method? It is easier to perform stubs in
    #       controller specs when you are calling a single method instead of a
    #       chain of methods.
    #
    # @return [Hash] a Ruby hash representation of a IIIF manifest document
    #
    # @see Hyrax::Configuration#iiif_manifest_cache_duration
    # @see Hyrax::WorksControllerBehavior
    def self.as_json(presenter:, iiif_manifest_factory: ::IIIFManifest::ManifestFactory, cache_manifest: Flipflop.cache_work_iiif_manifest?, expires_in: Hyrax.config.iiif_manifest_cache_duration)
      new(
        presenter: presenter,
        iiif_manifest_factory: iiif_manifest_factory,
        cache_manifest: cache_manifest,
        expires_in: expires_in
      ).as_json
    end

    # @api private
    def initialize(presenter:, iiif_manifest_factory:, cache_manifest:, expires_in:)
      @presenter = presenter
      @manifest_builder = iiif_manifest_factory.new(@presenter)
      @expires_in = expires_in
      @cache_manifest = cache_manifest
    end

    attr_reader :presenter, :manifest_builder, :expires_in, :cache_manifest
    alias cache_manifest? cache_manifest

    # @api private
    #
    # @return [Hash] a Ruby hash representation of a IIIF manifest document
    def as_json
      if cache_manifest?
        Rails.cache.fetch(manifest_cache_key, expires_in: expires_in) do
          sanitized_manifest
        end
      else
        sanitized_manifest
      end
    end

    private

      def sanitized_manifest
        # TODO: Do we really need to both convert to a JSON document then parse
        #       that document?
        hash = JSON.parse(manifest_builder.to_h.to_json)

        hash['label'] = sanitize_value(hash['label']) if hash.key?('label')
        hash['description'] = hash['description']&.collect { |elem| sanitize_value(elem) } if hash.key?('description')

        hash['sequences']&.each do |sequence|
          sequence['canvases']&.each do |canvas|
            canvas['label'] = sanitize_value(canvas['label'])
          end
        end
        hash
      end

      def sanitize_value(text)
        Loofah.fragment(text.to_s).scrub!(:prune).to_s
      end

      # By adding the Solr '_version_' field to the cache key, we shouldn't
      # run into the problem of fetching an outdated version of the manifest.
      #
      # @return [String]
      def manifest_cache_key
        "#{presenter.id}/#{presenter.solr_document['_version_']}"
      end
  end
end
