# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      # A `dry-transaction` step that mirrors a saved resource's `redirects`
      # entries into the `hyrax_redirect_paths` redirects table. The unique
      # index on `source_path` enforces global uniqueness at the DB level —
      # if a concurrent save already claimed a path, the insert raises
      # ActiveRecord::RecordNotUnique and this step returns Failure, which
      # short-circuits the enclosing transaction.
      #
      # Each row's `target_path` is computed once at write time:
      # - When the resource has an entry marked `display: true`, every
      #   row's `target_path` is that entry's path. Visitors landing on any
      #   alias are sent to the display alias.
      # - When no entry is marked `display: true`, every row's `target_path`
      #   is the resource's permanent UUID path (e.g.
      #   /concern/generic_works/<id>).
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
          changed_paths = replace_rows(object, build_rows(object))
          Hyrax::RedirectCacheBuster.call(changed_paths) if changed_paths
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
          entries = normalized_entries(object)
          return [] if entries.empty?

          target = target_path_for(object, entries)
          now = Time.current
          entries.map do |entry|
            {
              source_path: entry[:path],
              target_path: target,
              resource_id: object.id.to_s,
              display: entry[:display],
              created_at: now,
              updated_at: now
            }
          end
        end

        # Normalize the redirects array into a deduplicated list of
        # `{ path:, display: }` hashes with blank paths and dupes stripped.
        # Accepts string or symbol keys (Valkyrie's JSONValueMapper
        # symbolizes on read). Paths are already normalized at write time
        # by Hyrax::RedirectsNormalization.
        def normalized_entries(object)
          seen = Set.new
          Array(object.redirects).each_with_object([]) do |entry, acc|
            path = entry['path'] || entry[:path]
            next if path.blank?
            next if seen.include?(path)
            seen << path

            display = entry['display'] || entry[:display]
            acc << { path: path, display: display ? true : false }
          end
        end

        # If any entry is marked display, the display entry's path is the
        # shared target for every row. Otherwise the target is the
        # resource's permanent UUID path.
        def target_path_for(object, entries)
          display_entry = entries.find { |e| e[:display] }
          return display_entry[:path] if display_entry
          permanent_path_for(object)
        end

        # The UUID-based path Hyrax's routes naturally produce for this
        # resource. Collections route through the Hyrax engine; works route
        # through the host app's curation-concern resources.
        def permanent_path_for(object)
          if object.respond_to?(:pcdm_collection?) && object.pcdm_collection?
            Hyrax::Engine.routes.url_helpers.collection_path(object.id)
          else
            Rails.application.routes.url_helpers.polymorphic_path([:main_app, object])
          end
        rescue StandardError
          # Fall back to a path the controller can still handle.
          "/concern/generic_works/#{object.id}"
        end

        # @return [Array<String>, nil] the union of old + new source paths
        #   that need cache invalidation, or nil when nothing changed.
        def replace_rows(object, rows)
          desired = rows.map { |r| [r[:source_path], r[:target_path], r[:display]] }.sort

          Hyrax::RedirectPath.transaction do
            existing = Hyrax::RedirectPath
                       .where(resource_id: object.id.to_s)
                       .pluck(:source_path, :target_path, :display)
                       .sort
            return nil if desired == existing

            Hyrax::RedirectPath.where(resource_id: object.id.to_s).delete_all
            # rubocop:disable Rails/SkipsModelValidations -- the DB unique index on `source_path` is the validation we rely on; bulk insert is intentional
            Hyrax::RedirectPath.insert_all!(rows) if rows.any?
            # rubocop:enable Rails/SkipsModelValidations

            (existing.map(&:first) | desired.map(&:first))
          end
        end
      end
    end
  end
end
