# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Validates non-defaultness of the {Hyrax::AdministrativeSet}; gives `Success`
      # when not the default and `Failure` otherwise.
      #
      # Use this step to guard against destroying the default AdminSet.
      class CheckForDefaultAdminSet
        include Dry::Monads[:result]

        ##
        # @param [#find_inverse_references_by] query_service
        def initialize(query_service: Hyrax.query_service)
          @query_service = query_service
        end

        ##
        # @param [Hyrax::AdministrativeSet] admin_set
        #
        # @return [Dry::Monads::Result]
        def call(admin_set)
          return Failure["Administrative set cannot be deleted as it is the default set", admin_set] if admin_set.id == Hyrax.config.default_admin_set_id
          Success(admin_set)
        end
      end
    end
  end
end
