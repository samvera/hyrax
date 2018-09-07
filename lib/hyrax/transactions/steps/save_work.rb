# frozen_string_literal: true
module Hyrax
  module Transactions
    ##
    # A `dry-transaction` step that saves an input work.
    #
    # @since 2.4.0
    module Steps
      class SaveWork
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result] `Failure` if the work fails to save;
        #   `Success(input)`, otherwise.
        def call(work)
          work.save ? Success(work) : Failure(:not_saved)
        end
      end
    end
  end
end
