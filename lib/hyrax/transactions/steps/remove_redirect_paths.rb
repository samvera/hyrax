# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      # A `dry-transaction` step that removes a resource's rows from the
      # `hyrax_redirect_paths` redirects table. Runs as part of the destroy
      # transactions so deleted resources don't leave dangling claims on
      # redirect paths.
      #
      # See documentation/redirects.md.
      class RemoveRedirectPaths
        include Dry::Monads[:result]

        # @param [Valkyrie::Resource] resource
        # @return [Dry::Monads::Result]
        def call(resource)
          return Success(resource) unless removable?(resource)
          scope = Hyrax::RedirectPath.where(resource_id: resource.id.to_s)
          paths = scope.pluck(:from_path)
          scope.delete_all
          Hyrax::RedirectCacheBuster.call(paths) if paths.any?
          Success(resource)
        rescue ActiveRecord::StatementInvalid => e
          Hyrax.logger.error("[redirects] remove_redirect_paths failed: #{e.message}")
          Failure([:redirect_path_remove_error, e.message])
        end

        private

        def removable?(resource)
          Hyrax.config.redirects_enabled? && resource.respond_to?(:id) && resource.id.present?
        end
      end
    end
  end
end
