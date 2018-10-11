# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that sets the uploaded date to now for an
      # input work.
      #
      # @since 2.4.0
      class SetUploadedDate
        include Dry::Transaction::Operation

        ##
        # @note the current implementation sets the uploaded date to
        #   `#date_modified` if it exists, falling back on the current datetime.
        #
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result]
        def call(work)
          work.date_uploaded =
            work.date_modified || Hyrax::TimeService.time_in_utc
          Success(work)
        end
      end
    end
  end
end
