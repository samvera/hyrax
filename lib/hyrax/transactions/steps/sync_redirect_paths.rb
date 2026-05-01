# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      # A `dry-transaction` step that mirrors a saved resource's `redirects`
      # entries into the `hyrax_redirect_paths` uniqueness ledger. The unique
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
          replace_rows(object, build_rows(object))
          Success(object)
        rescue ActiveRecord::RecordNotUnique => e
          Failure([:redirect_path_collision, e.message])
        end

        private

        def syncable?(object)
          return false unless Hyrax.config.redirects_enabled? && Flipflop.redirects?
          object.respond_to?(:redirects) && object.respond_to?(:id) && object.id.present?
        end

        def build_rows(object)
          paths = Array(object.redirects)
                  .map { |entry| Hyrax::RedirectPathNormalizer.call(entry.try(:path)) }
                  .reject(&:blank?)
                  .uniq
          now = Time.current
          paths.map { |path| { path: path, resource_id: object.id.to_s, created_at: now, updated_at: now } }
        end

        def replace_rows(object, rows)
          Hyrax::RedirectPath.transaction do
            Hyrax::RedirectPath.where(resource_id: object.id.to_s).delete_all
            # rubocop:disable Rails/SkipsModelValidations -- the DB unique index on `path` is the validation we rely on; bulk insert is intentional
            Hyrax::RedirectPath.insert_all!(rows) if rows.any?
            # rubocop:enable Rails/SkipsModelValidations
          end
        end
      end
    end
  end
end
