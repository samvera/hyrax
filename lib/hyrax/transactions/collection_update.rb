# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Creates a Collection from a ChangeSet
    #
    # @since 3.2.0
    class CollectionUpdate < Transaction
      DEFAULT_STEPS = ['change_set.apply'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
