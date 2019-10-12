# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves a given work, returning a Result (Success|Failure)
      class Validate
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::ChangeSet] change_set
        #
        # @return [Dry::Monads::Result] `Success(input)` if the change_set is valid;
        #   `Failure`, otherwise.
        def call(change_set)
          return Success(change_set) if change_set.valid?

          Failure([:failed_validation, change_set.errors])
        end
      end
    end
  end
end
