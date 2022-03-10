# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transcation` step that destroys a Work.
      #
      # @since 3.0.0
      # @deprecated This is part of the legacy AF set of transaction steps for works.
      #   Transactions are not being used with AF works.  This will be removed in 4.0.
      # @see Hyrax::Transactions::Steps::DeleteResource
      class DestroyWork
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result]
        def call(work)
          work.destroy! && Success(work)
        rescue => err
          Failure(err)
        end
      end
    end
  end
end
