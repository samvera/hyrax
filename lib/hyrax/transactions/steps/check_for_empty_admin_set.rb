# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Validates emptiness of the {Hyrax::AdministrativeSet}; gives `Success`
      # when empty and `Failure` otherwise.
      #
      # Use this step to guard against destroying AdminSets with member objects.
      class CheckForEmptyAdminSet
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
          members = @query_service
                    .find_inverse_references_by(property: :admin_set_id,
                                                resource: admin_set)
          return Failure["Administrative set cannot be deleted as it is not empty", members] if members.any?

          Success(admin_set)
        end
      end
    end
  end
end
