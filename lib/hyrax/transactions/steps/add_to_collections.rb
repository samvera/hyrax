# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves a given work, returning a Result (Success|Failure)
      class AddToCollections
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [Array<#to_s>] collection_ids

        # @return [Dry::Monads::Result]
        def call(change_set, collection_ids: [])
          change_set.member_of_collection_ids += collection_ids

          Success(change_set)
        end
      end
    end
  end
end
