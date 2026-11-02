# frozen_string_literal: true

# OVERRIDE Valkyrie v3.6.1 to define the Hash key rules from samvera/valkyrie#1005
#
# Delete this file once Hyrax requires a Valkyrie release that includes samvera/valkyrie#1005 (tracked in samvera/hyrax#7703).
unless defined?(Valkyrie::Types::HashValue)
  module Valkyrie
    module Types
      # OVERRIDE (new): only the key rules; Valkyrie's Hash type normalization is
      # not needed, since Hyrax hash attributes use Dry::Types['hash'].
      module HashValue
        # Keys the adapters treat as an ID, a URI, an RDF literal, or a nested
        # resource.
        RESERVED_KEYS = [:id, :@id, :@value, :internal_resource].freeze
      end
    end
  end
end
