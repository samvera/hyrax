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
        def call(obj, permissions_params: [])
          return Success(obj) unless obj.respond_to?(:permission_manager)

          acl = obj.permission_manager&.acl
          # Translate step args into Hyrax::Permission objects before saving
          Array(permissions_params).each do |param|
            acl << param_to_permission(obj, param)
          end

          acl&.save || (return Failure[:failed_to_save_acl, acl])

          Success(obj)
        end

        private

        def param_to_permission(obj, param)
          mode = param["access"].to_sym
          agent = param["type"] == "group" ? "group/#{param['name']}" : param["name"]
          Hyrax::Permission.new(access_to: obj.id, mode: mode, agent: agent)
        end
      end
    end
  end
end
