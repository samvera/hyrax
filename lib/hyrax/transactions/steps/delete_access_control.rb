# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Deletes the Hyrax::AccessControlList for any resource with a `#permission_manager`.
      # If `#permission_manager` is undefined, succeeds.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class DeleteAccessControl
        include Dry::Monads[:result]

        ##
        # @param [Valkyrie::Resource] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj)
          return Success(obj) unless obj.respond_to?(:permission_manager)

          acl = obj.permission_manager&.acl
          return Success(obj) if acl.nil?

          acl.destroy || (return Failure[:failed_to_delete_acl, acl])

          Success(obj)
        end
      end
    end
  end
end
