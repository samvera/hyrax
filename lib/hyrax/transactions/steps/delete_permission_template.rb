# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Deletes the Hyrax::PermissionTemplate for a resource.
      # If no PermissionTemplate associated with that resource is found, succeeds.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class DeletePermissionTemplate
        include Dry::Monads[:result]

        ##
        # @param [Valkyrie::Resource] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj)
          permission_template = Hyrax::PermissionTemplate.find_by(source_id: obj.id)
          return Success(obj) if permission_template.nil?

          permission_template.destroy || (return Failure[:failed_to_delete_permission_template, permission_template])

          Success(obj)
        end
      end
    end
  end
end
