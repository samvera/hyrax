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
        def initialize(property: :file_ids, query_service: Hyrax.query_service, persister: Hyrax.persister, publisher: Hyrax.publisher)
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
            return Failure[:failed_to_delete_file_metadata, file_id] unless
              Hyrax::Transactions::Container['file_metadata.destroy']
              .call(@query_service.custom_queries.find_file_metadata_by(id: file_id))
              .success?
          rescue ::Ldp::Gone
            nil
          end

          Success(resource)
        end
      end
    end
  end
end
