# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transcation` step that applies permission templates from a
      # collection type on a given collection.
      #
      # @since 3.2.0
      class ApplyCollectionTypePermissions
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::PcdmCollection] collection with a collection type gid
        # @param user [User] the user that created the collection
        #
        # @return [Dry::Monads::Result]
        def call(collection, user: nil)
          Hyrax::Collections::PermissionsCreateService.create_default(collection: collection,
                                                                      creating_user: user)
          Success(collection)
        rescue URI::InvalidURIError => err
          # will be raised if the collection_type_gid is invalid or doesn't exist
          Failure(err)
        end
      end
    end
  end
end
