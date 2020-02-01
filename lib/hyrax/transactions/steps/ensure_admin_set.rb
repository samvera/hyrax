# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A step that ensures the input object has an `#admin_set_id`.
      #
      # @since 2.4.0
      class EnsureAdminSet
        include Dry::Monads[:result]

        ##
        # @param [#admin_set_id] obj
        #
        # @return [Dry::Monads::Result] `Failure` if there is no `AdminSet` for
        #   the input; `Success(input)`, otherwise.
        def call(obj)
          obj.admin_set_id ? Success(obj) : Failure(:no_admin_set_id)
        end
      end
    end
  end
end
