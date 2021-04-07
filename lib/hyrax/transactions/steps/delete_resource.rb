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
        def initialize(persister: Hyrax.persister)
          @persister = persister
        end

        ##
        # @param [Valkyrie::Resource] resource
        # @param [::User] the user resposible for the delete action
        #
        # @return [Dry::Monads::Result]
        def call(resource, user: nil)
          return Failure(:resource_not_persisted) unless resource.persisted?

          @persister.delete(resource: resource)
          Hyrax.publisher
               .publish('object.deleted', object: resource, id: resource.id.id, user: user)

          Success(resource)
        end
      end
    end
  end
end
