# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Updates a {Hyrax::FileSet} from a ChangeSet
    #
    # @since 3.4.0
    class FileSetUpdate < Transaction
      DEFAULT_STEPS = ['change_set.apply',
                       'file_set.save_acl'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
