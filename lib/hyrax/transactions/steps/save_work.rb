# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that saves an input work.
      #
      # @example saving a work
      #   step = Hyrax::Transactions::Steps::SaveWork.new
      #   work = MyWork.new(title: ['Comet in Moominland'])
      #
      #   step.call(work) # => Success
      #
      # @example handling error cases
      #   step = Hyrax::Transactions::Steps::SaveWork.new
      #   work = MyWork.new(title: [:invalid_title])
      #
      #   step.call(work).or { |err| puts err.messages }
      #
      # @since 2.4.0
      class SaveWork
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::WorkBehavior] work
        #
        # @return [Dry::Monads::Result] `Failure` if the work fails to save;
        #   `Success(input)`, otherwise.
        def call(work)
          work.save ? Success(work) : Failure(work.errors)
        end
      end
    end
  end
end
