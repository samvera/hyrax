# frozen_string_literal: true

module Hyrax
  module ValkyriePersistence
    module Postgres
      # OVERRIDE Valkyrie v3.5.1 — preserve compound entry boundaries on read.
      #
      # Valkyrie's Postgres read path (`JSONValueMapper`'s `EnumeratorValue`)
      # treats a single-key Hash as an enumerable and unwraps it to its
      # `[key, value]` pair. For a compound attribute persisted as an array of
      # one-field entry hashes — e.g. `[{ "name" => "Ada" }, { "role" => "Editor" }]`
      # — every entry is splayed, and the array collapses to
      # `[["name", "Ada"], ["role", "Editor"]]`, indistinguishable from a single
      # two-field entry. Downstream the two entries silently merge into one,
      # losing data on an ordinary save/reload.
      #
      # The raw JSONB on disk still holds the whole entries (the loss is purely
      # in the read conversion), so this override reads the compound attributes
      # straight from `orm_object.metadata` — bypassing the splay — and re-keys
      # each entry to match what the schema expects. It is scoped to the
      # resource's declared compounds only (via {Hyrax::CompoundSchema}); every
      # other attribute stays on Valkyrie's stock conversion path untouched.
      #
      # Compound discovery reads the effective schema, so this works in both flex
      # modes. {Hyrax::CompoundNormalization} and {Hyrax::Flexibility#load} remain
      # as the read-path repair for entry points that do not pass through this
      # converter (e.g. `.new` from a raw attribute hash, Wings conversion).
      module ORMConverterDecorator
        private

        # OVERRIDE: re-read compound attributes from the raw metadata without
        # the single-key-hash splay; leave all other attributes to `super`.
        def rdf_metadata
          base = super
          names = compound_attribute_names
          return base if names.empty?

          base.merge(unsplayed_compound_metadata(names))
        end

        # The compound attribute names declared for this record's resource class,
        # as strings (the keys present in the raw metadata hash). Empty when the
        # class has no compounds or the schema cannot be resolved — in which case
        # the override is inert and stock behavior stands.
        #
        # Resolves the class straight from the ORM object's `internal_resource`
        # column rather than `#resource_klass`: the latter reads through
        # `#attributes` -> `#rdf_metadata`, which this module overrides, so
        # calling it here would recurse.
        def compound_attribute_names
          klass = Valkyrie.config.resource_class_resolver.call(orm_object.internal_resource)
          Hyrax::CompoundSchema.for(klass).compound_names.map(&:to_s)
        rescue StandardError
          []
        end

        # For each compound key present in the raw JSONB, rebuild the value as an
        # array of whole entry hashes with symbolized keys — the shape the schema
        # coercion expects — instead of the splayed pairs `super` produced.
        def unsplayed_compound_metadata(names)
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
