# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Creates a Collection from a ChangeSet
    #
    # @since 3.2.0
    class CollectionCreate < Transaction
      DEFAULT_STEPS = ['change_set.set_user_as_depositor',
                       'change_set.set_collection_type_gid',
                       'change_set.add_to_collections',
                       'change_set.apply',
                       'collection_resource.apply_collection_type_permissions',
                       'collection_resource.save_acl'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
