# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # destroys a FileSet resource.
    #
    # @since 3.1.0
    class FileMetadataDestroy < Transaction
      DEFAULT_STEPS = ['file_metadata.delete'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
