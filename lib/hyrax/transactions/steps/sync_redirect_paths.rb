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
      # Each row stores a `target_path`: `nil` means "render in place at
      # source_path"; otherwise the resolver 301s to the stored target. The
      # entry marked `display_url: true` is always written with
      # `target_path = nil`, and every other entry on the same record gets
      # `target_path = <display entry's path>` (or `nil` when no entry is
      # marked).
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
          entries = extract_entries(object.redirects)
          display_path = entries.find { |e| e[:display_url] }&.dig(:path)
          now = Time.current
          entries.map { |entry| build_row(entry, object.id.to_s, display_path, now) }
        end

        # Valkyrie's JSONValueMapper symbolizes hash keys on read; accept either.
        # Paths are normalized at write time by Hyrax::RedirectsNormalization.
        def extract_entries(redirects)
          seen = Set.new
          Array(redirects).each_with_object([]) do |entry, acc|
            path = entry['path'] || entry[:path]
            next if path.blank? || seen.include?(path)
            seen << path
            acc << { path: path, display_url: truthy?(entry['display_url'] || entry[:display_url]) }
          end
        end

        def truthy?(value)
          value ? true : false
        end

        def build_row(entry, resource_id, display_path, now)
          target = entry[:display_url] ? nil : display_path
          { source_path: entry[:path],
            target_path: target,
            display_url: entry[:display_url],
            resource_id: resource_id,
            created_at: now, updated_at: now }
        end

        # @return [Array<String>, nil] the union of old + new source paths that
        #   need cache invalidation, or nil when nothing changed.
        def replace_rows(object, rows)
          desired = rows.map { |r| [r[:source_path], r[:target_path], r[:display_url]] }.sort

          Hyrax::RedirectPath.transaction do
            existing = Hyrax::RedirectPath.where(resource_id: object.id.to_s)
                                          .pluck(:source_path, :target_path, :display_url)
            return nil if desired == existing.sort

            Hyrax::RedirectPath.where(resource_id: object.id.to_s).delete_all
            # rubocop:disable Rails/SkipsModelValidations -- the DB unique index on `source_path` is the validation we rely on; bulk insert is intentional
            Hyrax::RedirectPath.insert_all!(rows) if rows.any?
            # rubocop:enable Rails/SkipsModelValidations

            (existing.map(&:first) | rows.map { |r| r[:source_path] })
          end
        end
      end
    end
  end
end
