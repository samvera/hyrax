# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Destroys a {Hyrax::PcdmCollection}
    #
    # @since 3.4.0
    class CollectionDestroy < Transaction
      # TODO: Add step that checks if collection is empty for collections of types that require it
      DEFAULT_STEPS = ['collection_resource.delete',
                       'collection_resource.delete_acl'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
