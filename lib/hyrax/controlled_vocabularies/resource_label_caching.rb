# frozen_string_literal: true
module Hyrax
  module ControlledVocabularies
    ##
    # adds caching to the {#rdf_label} method.
    #
    # for systems that check the {#rdf_label}and use {#fetch} to get upstream
    # data if it is not present, this can be used to avoid making round trips
    # to an authoritative web source.
    #
    # @see Hyrax::DeepIndexingService
    module ResourceLabelCaching
      CACHE_KEY_PREFIX = "hy_label-v1-"

      ##
      # @note uses the Rails cache to avoid repeated lookups.
      # @see ActiveTriples::Resource#rdf_label
      def rdf_label
        # only cache if this rdf source is represented by a URI;
        # i.e. don't cache for blank nodes
        return super unless uri?

        Rails.cache.fetch(cache_key) { super }
      end

      ##
      # @note adds behavior to clear the cache whenever a manual fetch of data
      #   is performed.
      # @see ActiveTriples::Resource#fetch
      def fetch(*, **)
        Rails.cache.delete(cache_key)
        super
      end

      private

      def cache_key
        "#{CACHE_KEY_PREFIX}#{to_uri.canonicalize.pname}"
      end
    end
  end
end
