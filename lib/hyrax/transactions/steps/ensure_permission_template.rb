# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that ensures the input `work` has a permission
      # template.
      #
      # @since 2.4.0
      # @deprecated This is part of the legacy AF set of transaction steps for works.
      #   Transactions are not being used with AF works.  This will be removed in 4.0.
      class EnsurePermissionTemplate
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result] `Failure` if there is no
        #   `PermissionTemplate` for the input; `Success(input)`, otherwise.
        def call(work)
          return Failure(:no_permission_template) unless
            Hyrax::PermissionTemplate.find_by(source_id: work.admin_set&.id)

          Success(work)
        end
      end
    end
  end
end
