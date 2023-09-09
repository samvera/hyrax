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
      class DeleteAllFileMetadata
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(property:, query_service: Hyrax.query_service, persister: Hyrax.persister, publisher: Hyrax.publisher)
          @property = property
          @persister = persister
          @query_service = query_service
          @publisher = publisher
        end

        ##
        # @param [Valkyrie::Resource] resource
        # @param [::User] the user resposible for the delete action
        #
        # @return [Dry::Monads::Result]
        def call(resource)
          return Failure(:resource_not_persisted) unless resource.persisted?

          resource[@property].each do |file_id|
            Hyrax::Transactions::Container['file_metadata.destroy'].call(@query_service.find_by(id: file_id))
          end

          Success(resource)
        end
      end
    end
  end
end
