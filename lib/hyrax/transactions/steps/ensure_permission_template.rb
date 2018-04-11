# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      class EnsurePermissionTemplate
        include Dry::Transaction::Operation

        def call(work)
          return Failure(:no_permission_template) unless
            Hyrax::PermissionTemplate.find_by(source_id: work.admin_set&.id)

          Success(work)
        end
      end
    end
  end
end
