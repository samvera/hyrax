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
      class FileMetadataDelete
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(persister: Hyrax.persister, storage_adapter: Hyrax.storage_adapter, publisher: Hyrax.publisher)
          @persister = persister
          @publisher = publisher
          @storage_adapter = storage_adapter
        end

        ##
        # @param [Hyrax::FileMetadata] FileMetadata resource
        # @param [::User] the user resposible for the delete action
        #
        # @return [Dry::Monads::Result]
        def call(resource)
          return Failure(:resource_not_persisted) unless resource.persisted?

          @persister.delete(resource: resource)
          @publisher.publish('file.metadata.deleted', metadata: resource)
          Valkyrie::StorageAdapter.delete(id: resource.file_identifier) if resource.file_identifier.present?

          Success(resource)
        end
      end
    end
  end
end
