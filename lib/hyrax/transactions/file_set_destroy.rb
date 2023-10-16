# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # destroys a FileSet resource.
    #
    # @since 3.1.0
    class FileSetDestroy < Transaction
      DEFAULT_STEPS = ['file_set.delete_all_file_metadata',
                       'file_set.remove_from_work',
                       'file_set.delete_acl',
                       'file_set.delete'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
