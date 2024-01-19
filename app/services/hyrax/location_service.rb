# frozen_string_literal: true
module Hyrax
  class LocationService < ::Qa::Authorities::Geonames
    CACHE_KEY_PREFIX = 'hyrax_geonames_label-v1-'
    CACHE_EXPIRATION = 1.week

    def full_label(uri)
      return if uri.blank?
      id = extract_id uri
      Rails.cache.fetch(cache_key(id), expires_in: CACHE_EXPIRATION) do
        label.call(find(id))
      end
    rescue URI::InvalidURIError
      # Old data may be just a string, display it.
      uri
    end

    private

    def extract_id(obj)
      uri = case obj
            when String
              URI(obj)
            when URI
              obj
            else
              raise ArgumentError, "#{obj} is not a valid type"
            end
      uri.path.split('/').last
    end

    def cache_key(id)
      "#{CACHE_KEY_PREFIX}#{id}"
    end
  end
end
