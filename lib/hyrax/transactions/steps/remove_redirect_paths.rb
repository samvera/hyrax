# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      # Removes a resource's rows from the `hyrax_redirect_paths` table on
      # destroy.
      #
      # See documentation/redirects.md.
      class RemoveRedirectPaths
        include Dry::Monads[:result]

        # @param [Valkyrie::Resource] resource
        # @return [Dry::Monads::Result]
        def call(resource)
          return Success(resource) unless removable?(resource)
          Hyrax::RedirectPath.where(resource_id: resource.id.to_s).delete_all
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
