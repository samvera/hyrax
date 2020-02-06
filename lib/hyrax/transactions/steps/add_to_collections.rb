# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Add a resource to collections via `ChangeSet`.
      #
      # Accepts `:collection_ids` and never retrieves the actual collections
      # from the persisted data. We trust that the identifiers passed refer to
      # actual, extant collections, and that the permissions to add to
      # collection membership have been established, or else that they'll be
      # validated prior to save.
      #
      # @since 3.0.0
      class AddToCollections
        include Dry::Monads[:result]

        ##
        # Add to collections by inserting collections to
        # `ChangeSet#member_of_collection_ids`.
        #
        # @param [Hyrax::ChangeSet] change_set
        # @param [Array<#to_s>] collection_ids
        #
        # @return [Dry::Monads::Result]
        def call(change_set, collection_ids: [])
          change_set.member_of_collection_ids += collection_ids

          Success(change_set)
        end
      end
    end
  end
end
