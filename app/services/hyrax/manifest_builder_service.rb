# frozen_string_literal: true

require 'iiif_manifest'

module Hyrax
  ##
  # A class responsible for converting a Hyrax::Work like thing into a IIIF
  # manifest.
  #
  # @see !{.as_json}
  class ManifestBuilderService
    ##
    # @api public
    #
    # @param presenter [Hyrax::WorkShowPresenter] the work presenter from which
    #        we'll build a manifest.
    # @param iiif_manifest_factory [Class] a class that initializes with presenter
    #        object and returns an object that responds to `#to_h`
    #
    # @note While the :presenter may be a Hyrax::WorkShowPresenter it is likely
    #       defined by Hyrax::WorksControllerBehavior.show_presenter
    #
    # @return [Hash] a Ruby hash representation of a IIIF manifest document
    #
    # @see Hyrax::WorksControllerBehavior
    def self.manifest_for(presenter:, iiif_manifest_factory: ::IIIFManifest::ManifestFactory)
      new(iiif_manifest_factory: iiif_manifest_factory)
        .manifest_for(presenter: presenter)
    end

    ##
    # @!attribute [r] manifest_factory
    #   @return [#to_h]
    attr_reader :manifest_factory

    ##
    # @api public
    #
    # @param iiif_manifest_factory [Class] a class that initializes with presenter
    #        object and returns an object that responds to `#to_h`
    def initialize(iiif_manifest_factory: ::IIIFManifest::ManifestFactory)
      @manifest_factory = iiif_manifest_factory
    end

    ##
    # @api public
    #
    # @param presenter [Hyrax::WorkShowPresenter]
    #
    # @return [Hash] a Ruby hash representation of a IIIF manifest document
    def manifest_for(presenter:)
      sanitized_manifest(presenter: presenter)
    end

    private

      ##
      # @api private
      # @param presenter [Hyrax::WorkShowPresenter]
      def sanitized_manifest(presenter:)
        # ::IIIFManifest::ManifestBuilder#to_h returns a
        # IIIFManifest::ManifestBuilder::IIIFManifest, not a Hash.
        # to get a Hash, we have to call its #to_json, then parse.
        #
        # wild times. maybe there's a better way to do this with the
        # ManifestFactory interface?
        manifest = manifest_factory.new(presenter).to_h
        hash = JSON.parse(manifest.to_json)

        hash['label'] = sanitize_value(hash['label']) if hash.key?('label')
        hash['description'] = hash['description']&.collect { |elem| sanitize_value(elem) } if hash.key?('description')

        hash['sequences']&.each do |sequence|
          sequence['canvases']&.each do |canvas|
            canvas['label'] = sanitize_value(canvas['label'])
          end
        end

        hash
      end

      ##
      # @api private
      # @param [#to_s] text
      # @return [String] a sanitized verison of `text`
      def sanitize_value(text)
        Loofah.fragment(text.to_s).scrub!(:prune).to_s
      end
  end
end
