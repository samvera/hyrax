# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that sets the `AdminSet` for an input work to
      # the default admin set, if none is already set. Creates the default
      # admin set if it doesn't already exist.
      class SetDefaultAdminSet
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result]
        def call(work)
          work.admin_set ||=
            AdminSet.find(AdminSet.find_or_create_default_admin_set_id)

          Success(work)
        end
      end
    end
  end
end
