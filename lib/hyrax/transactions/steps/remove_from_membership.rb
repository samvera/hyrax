# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Removes a collection from its members, returning a `Dry::Monads::Result`
      # (`Success`|`Failure`).
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class RemoveFromMembership
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(query_service: Hyrax.custom_queries, persister: Hyrax.persister, publisher: Hyrax.publisher)
          @persister = persister
          @query_service = query_service
          @publisher = publisher
        end

        ##
        # @param [Valkyrie::Resource] resource
        # @param [::User] the user resposible for the delete action
        #
        # @return [Dry::Monads::Result]
        def call(collection, user: nil)
          return Failure(:resource_not_persisted) unless collection.persisted?
          return Failure(:user_not_present) if user.blank?

          @query_service.find_members_of(collection: collection).each do |member|
            member.member_of_collection_ids -= [collection.id]
            @persister.save(resource: member)
            @publisher.publish('collection.membership.updated', collection: collection, user: user)
          rescue StandardError
            nil
          end

          Success(collection)
        end
      end
    end
  end
end
