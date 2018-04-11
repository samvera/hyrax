# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      class EnsureAdminSet
        include Dry::Transaction::Operation

        def call(work)
          work.admin_set_id ? Success(work) : Failure(:no_admin_set_id)
        end
      end
    end
  end
end
