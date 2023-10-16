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
          members = find_child_members(resource: resource)

          @persister.delete(resource: resource)
          publish_changes(resource: resource, user: user, members: members)

          Success(resource)
        end

        private

        def publish_changes(resource:, user:, members:)
          if resource.collection?
            @publisher.publish('collection.deleted',
                               collection: resource,
                               id: resource.id.id,
                               user: user,
                               members: members)
          else
            @publisher.publish('object.deleted',
                               object: resource,
                               id: resource.id.id,
                               user: user,
                               members: members)
          end
        end

        def find_child_members(resource:)
          if resource.collection?
            Hyrax.custom_queries.find_members_of(collection: resource)
          else
            Hyrax.custom_queries.find_child_file_sets(resource: resource)
          end
        end
      end
    end
  end
end
