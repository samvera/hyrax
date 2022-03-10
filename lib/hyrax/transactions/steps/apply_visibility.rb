# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that interprets visibility/lease/embargo from
      # passed arguments.
      #
      # @since 3.0.0
      # @deprecated This is part of the legacy AF set of transaction steps for works.
      #   Transactions are not being used with AF works.  This will be removed in 4.0.
      class ApplyVisibility
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        # @param [String] visibility
        # @param [String] release_date
        # @param [String] during
        # @param [String] after
        #
        # @return [Dry::Monads::Result] `Failure` if there is no
        #   `PermissionTemplate` for the input; `Success(input)`, otherwise.
        def call(work, visibility: nil, release_date: nil, during: nil, after: nil)
          return Success(work) if visibility.blank?

          intention = Hyrax::VisibilityIntention.new(visibility: visibility,
                                                     release_date: release_date,
                                                     during: during,
                                                     after: after)

          Hyrax::VisibilityIntentionApplicator.apply(intention).to(model: work)

          Success(work)
        rescue Hyrax::VisibilityIntentionApplicator::InvalidIntentionError => err
          Failure(err)
        end
      end
    end
  end
end
