# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves the Hyrax::AccessControlList for any resource with a `#permission_manager`.
      # If `#permission_manager` is undefined, succeeds.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class SaveAccessControl
        include Dry::Monads[:result]

        ##
        # @param [Valkyrie::Resource] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj)
          return Success(obj) unless obj.respond_to?(:permission_manager)
          obj.permission_manager&.acl&.save ||
            (return Failure[:failed_to_save_acl, acl])

          Success(obj)
        end
      end
    end
  end
end
