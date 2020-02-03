# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Applies and saves a `ChangeSet`.
    #
    # This transaction is intended to ensure appropriate results for a Hyrax
    # model when saving changes from a `ChangeSet`. For example: it will set the
    # system-managed metadata like modified date.
    #
    # If your application has custom system managed metadata, this is an
    # appropriate place to inject that behavior.
    #
    # This will also validate the `ChangeSet`. Which validations to use is
    # delegated on the `ChangeSet` itself.
    #
    # @since 3.0.0
    #
    # @example Applying a ChangeSet to a Work
    #   work = Hyrax::Work.new
    #   change_set = Hyrax::ChangeSet.for(work)
    #   change_set.title = ['Comet in Moominland']
    #
    #   transaction = Hyrax::Transactions::ApplyChangeSet.new
    #   result = transaction.call(change_set) # => Success(#<Hyrax::Work ...>)
    #
    #   result.bind(&:persisted?) => true
    #
    #   persisted = result.value_or { raise 'oh no!' } # safe unwrap
    #   persisted.title      # => ['Comet in Moominland']
    #
    class ApplyChangeSet < Transaction
      DEFAULT_STEPS = ['change_set.set_modified_date',
                       'change_set.set_uploaded_date_unless_present',
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
