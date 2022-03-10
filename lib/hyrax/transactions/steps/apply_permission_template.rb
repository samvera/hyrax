# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transcation` step that applies a permission template for a given
      # work's AdminSet.
      #
      # @since 2.4.0
      # @deprecated This is part of the legacy AF set of transaction steps for works.
      #   Transactions are not being used with AF works.  This will be removed in 4.0.
      class ApplyPermissionTemplate
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result]
        def call(work)
          return Failure(:missing_permission) unless
            (template = work&.admin_set&.permission_template)

          Hyrax::PermissionTemplateApplicator.apply(template).to(model: work)

          Success(work)
        rescue ActiveRecord::RecordNotFound => err
          Failure(err)
        end
      end
    end
  end
end
