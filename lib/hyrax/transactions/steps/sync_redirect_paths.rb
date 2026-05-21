# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      # A `dry-transaction` step that mirrors a saved resource's `redirects`
      # entries into the `hyrax_redirect_paths` redirects table. The unique
      # index on `from_path` enforces global uniqueness at the DB level — if
      # a concurrent save already claimed a path, the insert raises
      # ActiveRecord::RecordNotUnique and this step returns Failure, which
      # short-circuits the enclosing transaction.
      #
      # Every row carries the resource's canonical UUID URL in
      # `permalink_path`. Column semantics:
      #
      # - `from_path` — the URL the visitor entered (an alias or the UUID
      #   URL itself).
      # - `to_path` — the URL the address bar should display after the
      #   resolver routes the request. For the display row, equals its own
      #   `from_path` (the visitor stays at the display URL). For
      #   non-display rows, points at the display row's `from_path` (the
      #   visitor lands at the user-facing display URL). When no entry is
      #   marked, every alias's `to_path` is the UUID URL.
      # - `permalink_path` — the resource's canonical UUID URL. Constant
      #   per resource across all rows.
      #
      # When a display URL is set, the sync step also writes an extra row
      # with `from_path = permalink_path` so visitors hitting the bare
      # UUID URL are routed to the display alias.
      #
      # No-op when the redirects feature is off (config or Flipflop) or when
      # the resource doesn't carry the redirects attribute.
      #
      # See documentation/redirects.md.
      class SyncRedirectPaths
        include Dry::Monads[:result]

        # @param [Valkyrie::Resource] object the saved resource (must have an id)
        # @return [Dry::Monads::Result]
        def call(object)
          return Success(object) unless syncable?(object)
          replace_rows(object, build_rows(object))
          Success(object)
        rescue ActiveRecord::RecordNotUnique => e
          Failure([:redirect_path_collision, e.message])
        rescue ActiveRecord::StatementInvalid => e
          Hyrax.logger.error("[redirects] sync_redirect_paths failed: #{e.message}")
          Failure([:redirect_path_sync_error, e.message])
        end

        private

        def syncable?(object)
          return false unless Hyrax.config.redirects_active?
          object.respond_to?(:redirects) && object.respond_to?(:id) && object.id.present?
        end

        def build_rows(object)
          permalink = Hyrax::PermalinkPath.call(object)
          entries = entries_for(object)
          display_path = entries.find { |e| e[:is_display_url] }&.dig(:from_path)
          resource_id = object.id.to_s
          now = Time.current
          alias_rows = entries.map { |entry| build_alias_row(entry, resource_id, permalink, display_path, now) }
          alias_rows << build_permalink_row(resource_id, permalink, display_path, now) if display_path
          alias_rows
        end

        # Valkyrie's JSONValueMapper symbolizes hash keys on read; accept either.
        # Paths are normalized at write time by Hyrax::RedirectsNormalization.
        def entries_for(object)
          seen = Set.new
          Array(object.redirects).each_with_object([]) do |entry, acc|
            path = entry['path'] || entry[:path]
            next if path.blank? || seen.include?(path)
            seen << path
            acc << { from_path: path, is_display_url: display_url_flag(entry) }
          end
        end

        # Boolean-cast the stored value so importer/console writes that leave a
        # string like "false" or "0" in the JSONB hash don't end up as truthy.
        # Returns false when the key is absent.
        def display_url_flag(entry)
          raw = if entry.key?('is_display_url')
                  entry['is_display_url']
                elsif entry.key?(:is_display_url)
                  entry[:is_display_url]
                end
          ActiveModel::Type::Boolean.new.cast(raw) || false
        end

        def build_alias_row(entry, resource_id, permalink, display_path, now)
          to_path = if entry[:is_display_url]
                      entry[:from_path]
                    elsif display_path
                      display_path
                    else
                      permalink
                    end
          { from_path: entry[:from_path],
            to_path: to_path,
            permalink_path: permalink,
            resource_id: resource_id,
            is_display_url: entry[:is_display_url],
            created_at: now, updated_at: now }
        end

        def build_permalink_row(resource_id, permalink, display_path, now)
          { from_path: permalink,
            to_path: display_path,
            permalink_path: permalink,
            resource_id: resource_id,
            is_display_url: false,
            created_at: now, updated_at: now }
        end

        # Replaces the resource's rows when the set differs from what's
        # persisted. Skips the rewrite when the desired and existing rows
        # match (the common case on an update that didn't touch the
        # redirects attribute), to preserve `created_at` and avoid an
        # unnecessary DB transaction.
        def replace_rows(object, rows)
          desired = rows.map { |r| [r[:from_path], r[:to_path], r[:is_display_url]] }.sort

          Hyrax::RedirectPath.transaction do
            existing = Hyrax::RedirectPath.where(resource_id: object.id.to_s)
                                          .pluck(:from_path, :to_path, :is_display_url)
            return if desired == existing.sort

            Hyrax::RedirectPath.where(resource_id: object.id.to_s).delete_all
            # rubocop:disable Rails/SkipsModelValidations -- the DB unique index on `from_path` is the validation we rely on; bulk insert is intentional
            Hyrax::RedirectPath.insert_all!(rows) if rows.any?
            # rubocop:enable Rails/SkipsModelValidations
          end
        end
      end
    end
  end
end
