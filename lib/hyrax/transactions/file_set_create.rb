# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Creates a FileSet from a ChangeSet
    #
    class FileSetCreate < Transaction
      DEFAULT_STEPS = [
        'change_set.set_user_as_depositor',
        'change_set.apply',
        'file_set.add_file'
      ].freeze
      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
