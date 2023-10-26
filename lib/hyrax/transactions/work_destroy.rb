# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Destroys a work resource
    #
    # @since 3.0.0
    class WorkDestroy < Transaction
      DEFAULT_STEPS = ['work_resource.delete_all_file_sets',
                       'work_resource.delete_acl',
                       'work_resource.delete'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
