# frozen_string_literal: true

# OVERRIDE Valkyrie v3.6.1 to define the Hash key rules from samvera/valkyrie#1005
#
# Delete this file once Hyrax requires a Valkyrie release that includes #1005 (tracked in samvera/hyrax#7703).
unless defined?(Valkyrie::Types::HashValue)
  module Valkyrie
    module Types
      # OVERRIDE (new): only the key rules; Valkyrie's Hash type normalization is
      # not needed, since Hyrax hash attributes use Dry::Types['hash'].
      module HashValue
        # Keys become RDF predicates on Fedora.
        KEY_FORMAT = /\A[A-Za-z0-9_-]+\z/.freeze
        # Keys that adapters use for IDs and resource bookkeeping.
        RESERVED_KEYS = [:id, :internal_resource, :new_record, :member_ids, :created_at, :updated_at].freeze
      end
    end
  end
end
