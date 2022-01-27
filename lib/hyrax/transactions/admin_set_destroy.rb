# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Destroys a {Hyraxe::AdministrativeSet}
    #
    # @since 3.4.0
    class AdminSetDestroy < Transaction
      DEFAULT_STEPS = ['admin_set_resource.check_empty',
                       'admin_set_resource.delete'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
