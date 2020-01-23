# frozen_string_literal: true

module Hyrax
  # Isolate calls to ActiveFedora::Base
  class Base
    def self.uncached(&block)
      ActiveFedora::Base.uncached(&block)
    end

    def self.uri_to_id(uri)
      ActiveFedora::Base.uri_to_id(uri)
    end

    def self.id_to_uri(id)
      ActiveFedora::Base.id_to_uri(id)
    end
  end
end
