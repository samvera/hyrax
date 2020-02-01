# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Creates a Work from a ChangeSet
    #
    # @since 3.0.0
    class WorkCreate < Transaction
      DEFAULT_STEPS = ['change_set.set_default_admin_set',
                       'change_set.ensure_admin_set',
                       'change_set.apply'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
