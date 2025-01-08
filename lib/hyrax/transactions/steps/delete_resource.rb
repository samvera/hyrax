# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Deletes a resource from the persister, returning a `Dry::Monads::Result`
      # (`Success`|`Failure`).
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class DeleteResource
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(persister: Hyrax.persister, publisher: Hyrax.publisher)
          @persister = persister
          @publisher = publisher
        end

        ##
        # @param [Valkyrie::Resource] resource
        # @param [::User] the user resposible for the delete action
        #
        # @return [Dry::Monads::Result]
        def call(resource, user: nil)
          return Failure(:resource_not_persisted) unless resource.persisted?

          publish_changes(resource: resource, user: user)
          @persister.delete(resource: resource)

          Success(resource)
        end

        private

        def publish_changes(resource:, user:)
          if resource.collection?
            @publisher.publish('collection.deleted',
                               collection: resource,
                               id: resource.id.id,
                               user: user)
          else
            @publisher.publish('object.deleted',
                               object: resource,
                               id: resource.id.id,
                               user: user)
          end
        end
      end
    end
  end
end
