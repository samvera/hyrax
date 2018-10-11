# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that ensures the input `work` has an AdminSet.
      #
      # @since 2.4.0
      class EnsureAdminSet
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result] `Failure` if there is no `AdminSet` for
        #   the input; `Success(input)`, otherwise.
        def call(work)
          work.admin_set_id ? Success(work) : Failure(:no_admin_set_id)
        end
      end
    end
  end
end
