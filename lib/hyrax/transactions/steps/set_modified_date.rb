# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that sets the modified date to now for an
      # input work.
      #
      # @since 2.4.0
      class SetModifiedDate
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result]
        def call(work)
          work.date_modified = Hyrax::TimeService.time_in_utc

          Success(work)
        end
      end
    end
  end
end
