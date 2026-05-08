# frozen_string_literal: true

module Hyrax
  # Invalidates the redirect-resolution cache entries for a set of paths.
  #
  # The RedirectsController caches Solr lookups under a key derived from
  # the normalized path. This service deletes those keys so that saves and
  # destroys take effect immediately instead of waiting for the 60s TTL.
  #
  # See documentation/redirects.md.
  class RedirectCacheBuster
    # @param paths [Array<String>] unnormalized or normalized redirect paths
    def self.call(paths)
      Array(paths).each do |path|
        normalized = Hyrax::RedirectPathNormalizer.call(path)
        Rails.cache.delete(cache_key_for(normalized))
      end
    end

    # The cache key format used by RedirectsController#lookup. Kept here as
    # the single source of truth; the controller delegates to this method.
    #
    # @param normalized_path [String] a path already run through RedirectPathNormalizer
    # @return [String]
    def self.cache_key_for(normalized_path)
      ['hyrax', 'redirects', Digest::SHA1.hexdigest(normalized_path)].join('/')
    end
  end
end
