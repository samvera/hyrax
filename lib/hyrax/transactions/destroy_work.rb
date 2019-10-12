# frozen_string_literal: true
module Hyrax
  module Transactions
    ##
    # A transaction for destroying a Hyrax Work.
    #
    # @note This is an experimental replacement for the actor stack's `#destroy`
    #   stack. In time, we hope this will have feature parity with that stack,
    #   along with improved architecture, error handling, readability, and
    #   customizability. While this develops, please provide feedback.
    #
    # @since 3.0.0
    #
    # @see https://dry-rb.org/gems/dry-transaction/
    #
    # @deprecated Development on Dry::Transaction has been discontinued, we're
    #   removing existing transactions and replacing them with Dry::Monad-based
    #   valkyrie versions.
    class DestroyWork
      include Dry::Transaction(container: Hyrax::Transactions::Container)

      step :destroy_work, with: 'work.destroy_work'
    end
  end
end
