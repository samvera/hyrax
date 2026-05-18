# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      # A `dry-transaction` step that mirrors a saved resource's `redirects`
      # entries into the `hyrax_redirect_paths` redirects table. The unique
      # index on `path` enforces global uniqueness at the DB level — if a
      # concurrent save already claimed a path, the insert raises
      # ActiveRecord::RecordNotUnique and this step returns Failure, which
      # short-circuits the enclosing transaction.
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
          # Valkyrie's JSONValueMapper symbolizes hash keys on read; accept either.
          # Paths are normalized at write time by Hyrax::RedirectsNormalization.
          seen = Set.new
          now = Time.current
          Array(object.redirects).each_with_object([]) do |entry, rows|
            path = entry['path'] || entry[:path]
            next if path.blank? || seen.include?(path)
            seen << path

            display_url = entry['display_url'] || entry[:display_url]
            rows << { path: path, resource_id: object.id.to_s, display_url: display_url ? true : false,
                      created_at: now, updated_at: now }
          end
        end

        # @return [Array<String>, nil] the union of old + new paths that need
        #   cache invalidation, or nil when nothing changed.
        def replace_rows(object, rows)
          desired = rows.map { |r| [r[:path], r[:display_url]] }.sort

          Hyrax::RedirectPath.transaction do
            existing_rows = Hyrax::RedirectPath.where(resource_id: object.id.to_s).pluck(:path, :display_url)
            return nil if desired == existing_rows.sort

            Hyrax::RedirectPath.where(resource_id: object.id.to_s).delete_all
            # rubocop:disable Rails/SkipsModelValidations -- the DB unique index on `path` is the validation we rely on; bulk insert is intentional
            Hyrax::RedirectPath.insert_all!(rows) if rows.any?
            # rubocop:enable Rails/SkipsModelValidations

            (existing_rows.map(&:first) | rows.map { |r| r[:path] })
          end
        end
      end
    end
  end
end
