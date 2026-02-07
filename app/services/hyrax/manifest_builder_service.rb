# frozen_string_literal: true

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
    def self.manifest_for(presenter:, iiif_manifest_factory: Hyrax.config.iiif_manifest_factory)
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
    def initialize(iiif_manifest_factory: Hyrax.config.iiif_manifest_factory)
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
      manifest = manifest_factory.new(presenter).to_h
      hash = manifest.respond_to?(:inner_hash) ? manifest.inner_hash : JSON.parse(manifest.to_json)
      deep_sanitize(hash)
    end

    ##
    # @api private
    # Recursively sanitizes all strings in a nested data structure
    # @param obj [Object] the object to sanitize (Hash, Array, String, or other)
    # @return [Object] sanitized version maintaining the original structure
    def deep_sanitize(obj)
      case obj
      when Hash
        obj.transform_values { |v| deep_sanitize(v) }
      when Array
        obj.map { |v| deep_sanitize(v) }
      when String
        CGI.unescapeHTML(Loofah.fragment(obj.to_s).scrub!(:prune).to_s)
      else
        obj
      end
    end
  end
end
