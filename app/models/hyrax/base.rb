# frozen_string_literal: true

module Hyrax
  # Isolate calls to ActiveFedora::Base
  class Base
    def self.uncached(&block)
      ActiveFedora::Base.uncached(&block)
    end

    def self.uri_to_id(uri)
      Hyrax.config.translate_uri_to_id.call(uri)
    end

    def self.id_to_uri(id)
      Hyrax.config.translate_id_to_uri.call(id)
    end
  end
end
