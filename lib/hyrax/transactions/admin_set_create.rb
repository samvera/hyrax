# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Creates a Collection from a ChangeSet
    #
    # @since 3.2.0
    class AdminSetCreate < Transaction
      DEFAULT_STEPS = ['change_set.apply',
                       'admin_set_resource.apply_collection_type_permissions',
                       'admin_set_resource.save_acl'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
