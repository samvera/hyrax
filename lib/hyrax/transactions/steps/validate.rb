# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Validates a ChangeSet, returning `Success(change_set)` if valid, and
      # a `Failure` including the errors otherwise.
      #
      # Callers provide the particular `ChangeSet` to validate, and its validity
      # status is delegated by its own configuration/implementation.
      #
      # It is good practice to run this validation as a precursor to any step
      # that will sync a ChangeSet or save its resource. A `Failure` return
      # value in the context of a transaction will prevent the sync/save step
      # from running.
      #
      # @since 3.0.0
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
