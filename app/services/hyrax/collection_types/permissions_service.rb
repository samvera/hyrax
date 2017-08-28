module Hyrax
  module CollectionTypes
    class PermissionsService
      # @api public
      #
      # Get a list of collection types that a user can create
      #
      # @param user [User] the user that will be creating a collection (default: current_user)
      # @return [Array<Hyrax::CollectionType>] array of collection types the user can create
      def self.can_create_collection_types(user: current_user)
        # Stubbed to return all types.  Implement according to issue #1582
        return Hyrax::CollectionType.all if user.present? # condition test added to allow paramter to be present
        []
      end
    end
  end
end
