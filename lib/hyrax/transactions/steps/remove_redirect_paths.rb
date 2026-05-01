# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      # A `dry-transaction` step that removes a resource's rows from the
      # `hyrax_redirect_paths` uniqueness ledger. Runs as part of the destroy
      # transactions so deleted resources don't leave dangling claims on
      # redirect paths.
      #
      # See documentation/redirects.md.
      class RemoveRedirectPaths
        include Dry::Monads[:result]

        # @param [Valkyrie::Resource] resource
        # @return [Dry::Monads::Result]
        def call(resource)
          if Hyrax.config.redirects_enabled? && resource.respond_to?(:id) && resource.id.present?
            Hyrax::RedirectPath.where(resource_id: resource.id.to_s).delete_all
          end
          Success(resource)
        end
      end
    end
  end
end
