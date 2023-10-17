# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Deletes a resource's member FileSets from the persister, returning a `Dry::Monads::Result`
      # (`Success`|`Failure`).
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class DeleteAllFileSets
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(query_service: Hyrax.query_service, persister: Hyrax.persister, publisher: Hyrax.publisher)
          @persister = persister
          @query_service = query_service
          @publisher = publisher
        end

        ##
        # @param [Valkyrie::Resource] resource
        # @param [::User] the user resposible for the delete action
        #
        # @return [Dry::Monads::Result]
        def call(resource, user: nil)
          return Failure(:resource_not_persisted) unless resource.persisted?

          @query_service.custom_queries.find_child_file_sets(resource: resource).each do |file_set|
            return Failure[:failed_to_delete_file_set, file_set] unless
              Hyrax::Transactions::Container['file_set.destroy']
              .with_step_args('file_set.remove_from_work' => { user: user },
                              'file_set.delete' => { user: user })
              .call(file_set).success?
          rescue ::Ldp::Gone
            nil
          end

          Success(resource)
        end
      end
    end
  end
end
