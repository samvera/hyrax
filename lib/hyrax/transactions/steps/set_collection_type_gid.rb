# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A step that sets the `#collection_type_gid` in the change set.
      #
      # @since 3.2.0
      class SetCollectionTypeGid
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param collection_type_gid [URI::GID] global id for the collection type
        # @return [Dry::Monads::Result] `Failure` if there is no `collection_type_gid` or
        #   it can't be set to the default for the input; `Success(input)`, otherwise.
        def call(change_set, collection_type_gid: default_collection_type_gid)
          return Failure[:no_collection_type_gid, collection] unless
            change_set.respond_to?(:collection_type_gid=)
          return Success(change_set) if
            change_set.collection_type_gid.present?

          change_set.collection_type_gid = collection_type_gid
          Success(change_set)
        end

        private

        def default_collection_type_gid
          Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id
        end
      end
    end
  end
end
