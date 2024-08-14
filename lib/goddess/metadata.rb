# frozen_string_literal: true

module Goddess
  module Metadata
    # @return [Valkyrie::ID] Identifier for this metadata adapter.
    def id
      @id ||= begin
                to_hash = "migrate_adapter"
                ::Valkyrie::ID.new(Digest::MD5.hexdigest(to_hash))
              end
    end
  end
end
