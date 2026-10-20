# frozen_string_literal: true
require 'valkyrie/persistence/fedora'

# OVERRIDE Valkyrie v3.6.1 to read plain Hash values stored in an earlier, unreleased format
#
# Between samvera/hyrax#7667 and samvera/hyrax#7704, Hyrax's main branch stored
# each plain Hash on Fedora as a nested graph marked with this internal_resource,
# instead of the JSON literal Valkyrie now uses. Only the sirenia test deployment
# (Valkyrie Fedora adapter) holds data in that format. Without this, Valkyrie
# tries to load the marker as a resource class and the whole work fails to load.
# A work is rewritten in the JSON format the next time it is saved. An array
# inside such a Hash was stored as an RDF list: an empty one reads back as [],
# and a one-element one reads back as its single value.
#
# This is independent of the Valkyrie version. Delete this file once that
# deployment no longer holds such data.
module Hyrax
  module ValkyriePersistence
    module Fedora
      module LegacyHashGraphSupport
        LEGACY_HASH_MARKER = "Valkyrie::InternalHash"

        def convert
          attrs = attributes
          # OVERRIDE: a Hash in the earlier format reads back as just its own keys
          return legacy_hash(attrs) if attrs[:internal_resource] == LEGACY_HASH_MARKER
          populate_native_lock(::Valkyrie::Types::Anything[attrs])
        end

        private

        def legacy_hash(attrs)
          attrs.except(:id, :new_record, :internal_resource).transform_values { |val| val == RDF.nil ? [] : val }
        end
      end
    end
  end
end

Valkyrie::Persistence::Fedora::Persister::OrmConverter.prepend(Hyrax::ValkyriePersistence::Fedora::LegacyHashGraphSupport)
