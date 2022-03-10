# frozen_string_literal: true
module Hyrax
  module Transactions
    ##
    # @since 3.0.0
    # @deprecated Use Hyrax::Transactions::WorkUpdate instead.
    class UpdateWork < Transaction
      DEFAULT_STEPS = Hyrax::Transactions::WorkUpdate::DEFAULT_STEPS

      # DO NOT USE - This class is deprecated.  Use Hyrax::Transactions::WorkUpdate instead.

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
