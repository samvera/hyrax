# frozen_string_literal: true

# OVERRIDE Valkyrie v3.6.1 to keep one-key Hash values whole on Postgres, mirroring samvera/valkyrie#1005
#
# Delete this file once Hyrax requires a Valkyrie release that includes #1005.
module Hyrax
  module ValkyriePersistence
    module Shared
      module NestedRecordOverride
        # OVERRIDE: claim every non-empty Hash, not only multi-key ones.
        # Hashes shaped as RDF literals, IDs, or URIs are claimed by the mappers
        # registered before this one; a single-key Hash would otherwise fall to
        # EnumeratorValue, which unwraps it to a bare [key, value] pair.
        def handles?(value)
          value.is_a?(Hash) && !value.empty?
        end
      end
    end
  end
end

Valkyrie::Persistence::Shared::JSONValueMapper::NestedRecord
  .singleton_class.prepend(Hyrax::ValkyriePersistence::Shared::NestedRecordOverride)
