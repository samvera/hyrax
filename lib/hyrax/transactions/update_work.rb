# frozen_string_literal: true
module Hyrax
  module Transactions
    ##
    # @since 3.0.0
    class UpdateWork < Transaction
      DEFAULT_STEPS = ['change_set.apply'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
