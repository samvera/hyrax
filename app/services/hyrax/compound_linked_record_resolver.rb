# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Registry and resolver for the `linked_record` compound sub-property type,
  # whose stored value is a reference to a row in a database table. Turns that
  # stored id into a display label and a show path — the database-backed
  # analogue of {Hyrax::CompoundWorkResolver}, which resolves work ids via Solr.
  #
  # Generic by design: each linked source registers how to find a record, how to
  # label it, how to build its show path, how to search the table (for the
  # picker autocomplete), and — optionally — how to create one (for the
  # profile-driven lookup-or-create flow). The resolver stays naive about which
  # tables exist; the host application names its own sources.
  #
  #   Hyrax::CompoundLinkedRecordResolver.register(
  #     :people,
  #     finder: ->(id) { Person.find_by(id:) },
  #     label:  ->(p)  { p.display_name },
  #     path:   ->(p)  { Rails.application.routes.url_helpers.person_path(p) },
  #     search: ->(q)  { Person.matching(q).limit(20).map { |p| { id: p.id.to_s, label: p.display_name, value: p.id.to_s } } },
  #     create: ->(attrs) { Person.create(attrs.slice(:display_name, :orcid)) }
  #   )
  #
  # The M3 profile names the source via the sub-property's `authority:` key; see
  # documentation/compound_fields.md.
  class CompoundLinkedRecordResolver
    Source = Struct.new(:finder, :label, :path, :search, :create, keyword_init: true)

    class << self
      # @return [Hash{Symbol => Source}] the registered sources, by name
      def registry
        @registry ||= {}
      end

      # Register a linked source: the procs that map between a stored id and a
      # database record. `search` and `create` are optional — omit them for a
      # source that is resolve-only (no picker autocomplete, no inline creation).
      #
      # @param source [Symbol, String] the source name, matched to a
      #   sub-property's `authority:` in the M3 profile
      # @param finder [#call] `(id) -> record | nil`
      # @param label  [#call] `(record) -> String` the display label
      # @param path   [#call] `(record) -> String` the record's show path
      # @param search [#call, nil] `(query) -> Array<{id:, label:, value:}>` for
      #   the picker autocomplete
      # @param create [#call, nil] `(attributes Hash) -> record` for the
      #   lookup-or-create flow. A scalar create-field arrives as a single value;
      #   a `group` create-field arrives as an Array of Hashes (one per row).
      def register(source, finder:, label:, path:, search: nil, create: nil)
        registry[source.to_sym] = Source.new(finder:, label:, path:, search:, create:)
      end

      # @param source [Symbol, String]
      # @return [Boolean] whether the source is registered with a `search` proc
      def searchable?(source)
        registry[source.to_sym]&.search.present?
      end

      # @param source [Symbol, String]
      # @return [Boolean] whether the source is registered with a `create` proc
      def creatable?(source)
        registry[source.to_sym]&.create.present?
      end

      # @param source [Symbol, String]
      # @param query [String] the typed search term
      # @return [Array<Hash{Symbol => String}>] picker results
      #   (`{ id:, label:, value: }`); `[]` when the source is unregistered or
      #   not searchable
      def search(source, query)
        spec = registry[source.to_sym]
        return [] if spec.nil? || spec.search.nil?

        Array(spec.search.call(query))
      rescue StandardError => e
        Hyrax.logger.debug("CompoundLinkedRecordResolver.search(#{source}, #{query}): #{e.message}")
        []
      end

      # Create a record for the source from the given attributes. The source's
      # `create` proc owns validation; it may return a record with errors or raise.
      #
      # @param source [Symbol, String]
      # @param attrs [Hash] the create-form attributes
      # @return [Object, nil] the new record (resolvable via the same source), or
      #   nil when the source is unregistered or not creatable
      def create(source, attrs)
        spec = registry[source.to_sym]
        return nil if spec.nil? || spec.create.nil?

        spec.create.call(attrs)
      end

      # @param source [Symbol, String]
      # @param id [String] the stored row id
      # @return [Array(String, String), nil] `[label, path]`, or nil when the
      #   source is unregistered or the record is not found (so callers can
      #   render a bare, unlinked value)
      def resolve(source, id)
        record = find(source, id)
        return nil if record.nil?

        spec = registry[source.to_sym]
        [spec.label.call(record), spec.path.call(record)]
      end

      # @param source [Symbol, String]
      # @param id [String] the stored row id
      # @param label_field [String, nil] a field to read off the record (from the
      #   profile's `view: { label_field: }`); falls back to the source's `label`
      #   proc when absent/blank/unsupported
      # @return [String] the record's label, or the id string when unresolved
      def label_for(source, id, label_field: nil)
        record = find(source, id)
        record ? record_label(registry[source.to_sym], record, label_field) : id.to_s
      end

      # @param source [Symbol, String]
      # @param id [String] the stored row id
      # @return [String, nil] the record's show path, or nil when unresolved
      def path_for(source, id)
        record = find(source, id)
        record ? registry[source.to_sym].path.call(record) : nil
      end

      # Label + path with id/nil fallbacks when unresolved — convenient for the
      # form pre-fill and show-page rendering.
      #
      # @param source [Symbol, String]
      # @param id [String] the stored row id
      # @param label_field [String, nil] see {.label_for}
      # @return [Array(String, String), Array(String, nil)] `[label, path]` when
      #   resolved, else `[id, nil]`
      def title_and_path(source, id, label_field: nil)
        record = find(source, id)
        return [id.to_s, nil] if record.nil?

        spec = registry[source.to_sym]
        [record_label(spec, record, label_field), spec.path.call(record)]
      end

      # The raw record, so callers that need fields beyond label/path (e.g. an
      # external identifier) can read them off it.
      #
      # @param source [Symbol, String]
      # @param id [String] the stored row id
      # @return [Object, nil] the record, or nil when unregistered/blank/unfound
      def find(source, id)
        spec = registry[source.to_sym]
        return nil if spec.nil? || id.blank?

        spec.finder.call(id)
      rescue StandardError => e
        Hyrax.logger.debug("CompoundLinkedRecordResolver.find(#{source}, #{id}): #{e.message}")
        nil
      end

      private

      # Prefer the profile-declared `label_field` read off the record; fall back
      # to the source's registered label proc (when no field is named, the field
      # is blank, or the record doesn't expose it).
      def record_label(spec, record, label_field)
        if label_field.present? && record.respond_to?(label_field)
          value = record.public_send(label_field)
          return value.to_s if value.present?
        end
        spec.label.call(record)
      end
    end
  end
end
