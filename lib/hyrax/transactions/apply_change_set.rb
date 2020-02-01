# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Applies and saves a ChangeSet.
    #
    # @since 3.0.0
    #
    # @example Applying a ChangeSet to a Work
    #   work = Hyrax::Work.new
    #   change_set = Hyrax::ChangeSet.for(work)
    #   change_set.title = ['Comet in Moominland']
    #
    #   transaction = Hyrax::Transactions::ApplyChangeSet.new
    #   result = transaction.call(change_set)
    #
    #   result.bind(&:persisted?) => true
    #
    #   persisted = result.value_or { raise 'oh no!' } # safe unwrap
    #   persisted.title      # => ['Comet in Moominland']
    #
    class ApplyChangeSet < Transaction
      DEFAULT_STEPS = ['change_set.set_modified_date',
                       'change_set.set_uploaded_date',
                       'change_set.validate',
                       'change_set.save'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
