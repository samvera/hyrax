# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A step that sets the `AdminSet` for an input work to the default admin
      # set if none is already set. Creates the default admin set if it doesn't
      # already exist.
      #
      # @since 2.4.0
      class SetDefaultAdminSet
        include Dry::Monads[:result]

        ##
        # @param [#admin_set_id=] obj
        #
        # @return [Dry::Monads::Result]
        def call(obj)
          obj.admin_set_id ||= AdminSet.find_or_create_default_admin_set_id

          Success(obj)
        end
      end
    end
  end
end
