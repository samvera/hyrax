# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      class SetDefaultAdminSet
        include Dry::Transaction::Operation

        def call(work)
          work.admin_set ||=
            AdminSet.find(AdminSet.find_or_create_default_admin_set_id)

          Success(work)
        end
      end
    end
  end
end
