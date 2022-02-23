# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Updates a Collection from a ChangeSet
    #
    # @since 3.2.0
    class CollectionUpdate < Transaction
      DEFAULT_STEPS = ['change_set.apply',
                       'collection_resource.save_collection_banner',
                       'collection_resource.save_collection_logo',
                       'collection_resource.save_acl'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
