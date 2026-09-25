# frozen_string_literal: true

module Hyrax
  module ValkyriePersistence
    module Postgres
      # OVERRIDE Valkyrie v3.6.1 — preserve hash entry boundaries on read.
      #
      # Valkyrie's Postgres read path (`JSONValueMapper`'s `EnumeratorValue`)
      # treats a single-key Hash as an enumerable and unwraps it to its
      # `[key, value]` pair. For a `type: hash` attribute persisted as an array
      # of one-field entry hashes — e.g. `[{ "name" => "Ada" }, { "role" => "Editor" }]`
      # or a path-only redirect `[{ "path" => "/x" }]` — every entry is splayed.
      # A compound then silently merges the entries into one; any other hash
      # attribute fails its type check, so the save raises after the row is
      # already written.
      #
      # The raw JSONB on disk still holds the whole entries (the loss is purely
      # in the read conversion), so this override reads the hash attributes
      # straight from `orm_object.metadata` — bypassing the splay — and re-keys
      # each entry to match what the schema expects. It is scoped to the
      # resource's `type: hash` attributes only (via {Hyrax::CompoundSchema});
      # every other attribute stays on Valkyrie's stock conversion path untouched.
      #
      # Attribute discovery reads the effective schema, so this works in both flex
      # modes. {Hyrax::CompoundNormalization} and {Hyrax::Flexibility#load} remain
      # as the read-path repair for entry points that do not pass through this
      # converter (e.g. `.new` from a raw attribute hash, Wings conversion).
      module ORMConverterDecorator
        private

        # OVERRIDE: re-read hash attributes from the raw metadata without
        # the single-key-hash splay; leave all other attributes to `super`.
        def rdf_metadata
          base = super
          names = hash_attribute_names
          return base if names.empty?

          base.merge(unsplayed_hash_metadata(names))
        end

        # The `type: hash` attribute names declared for this record's resource
        # class, as strings (the keys present in the raw metadata hash). Empty
        # when the class has none or the schema cannot be resolved — in which
        # case the override is inert and stock behavior stands.
        #
        # Resolves the class straight from the ORM object's `internal_resource`
        # column rather than `#resource_klass`: the latter reads through
        # `#attributes` -> `#rdf_metadata`, which this module overrides, so
        # calling it here would recurse.
        #
        # Cached per request: in flexible mode the lookup reads the profile at
        # the record's schema version, which would otherwise repeat for every row.
        def hash_attribute_names
          version = Array.wrap(orm_object.metadata['schema_version']).first
          cache = (Hyrax::Current.stored_hash_attribute_names ||= {})
          cache[[orm_object.internal_resource, version]] ||= begin
            klass = Valkyrie.config.resource_class_resolver.call(orm_object.internal_resource)
            Hyrax::CompoundSchema.for_stored_record(klass, version).hash_attribute_names.map(&:to_s)
          end
        rescue StandardError
          []
        end

        # For each hash attribute present in the raw JSONB, rebuild the value as
        # an array of whole entry hashes with symbolized keys — the shape the
        # schema coercion expects — instead of the splayed pairs `super` produced.
        def unsplayed_hash_metadata(names)
          raw = orm_object.metadata
          names.each_with_object({}) do |name, acc|
            next unless raw.key?(name)

            entries = Array.wrap(raw[name]).map do |entry|
              entry.is_a?(::Hash) ? entry.symbolize_keys : entry
            end
            acc[name] = entries
          end
        end
      end
    end
  end
end

Valkyrie::Persistence::Postgres::ORMConverter.prepend(
  Hyrax::ValkyriePersistence::Postgres::ORMConverterDecorator
)
