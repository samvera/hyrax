# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Updates a {Hyrax::AdministrativeSet} from a ChangeSet
    #
    # @since 3.4.0
    class AdminSetUpdate < Transaction
      DEFAULT_STEPS = ['change_set.apply',
                       'admin_set_resource.save_acl'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
