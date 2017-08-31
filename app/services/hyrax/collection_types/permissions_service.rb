module Hyrax
  module CollectionTypes
    class PermissionsService
      # @api public
      #
      # What types of collection can the user create or manage
      #
      # @param user [User] user - The user requesting to create/manage a Collection
      # @param roles [String] type of access, 'manage' and/or 'create'
      # @return [Array<Hyrax::CollectionType>]
      def self.collection_types_for_user(user:, roles:)
        return Hyrax::CollectionType.all if user.groups.include? 'admin'
        ids = Hyrax::CollectionTypeParticipant.where(agent_type: 'user',
                                                     agent_id: user.user_key,
                                                     access: roles)
                                              .or(
                                                CollectionTypeParticipant.where(agent_type: 'group',
                                                                                agent_id: user.groups,
                                                                                access: roles)
                                              ).pluck('DISTINCT hyrax_collection_type_id')
        Hyrax::CollectionType.where(id: ids)
      end

      # @api public
      #
      # Get a list of collection types that a user can create
      #
      # @param user [User] the user that will be creating a collection (default: current_user)
      # @return [Array<Hyrax::CollectionType>] array of collection types the user can create
      def self.can_create_collection_types(user: current_user)
        collection_types_for_user(user: user, roles: ['manage', 'create'])
      end

      # @api public
      #
      # Get a list of users who should be added as user editors for a new collection of the specified collection type
      #
      # @param collection_type [Hyrax::CollectionType] the type of the collection being created
      # @return [Array<String>] array of user identifiers (typically emails) for users who can edit collections of this type
      def self.user_edit_grants_for_collection_of_type(collection_type: nil)
        return [] unless collection_type
        # Stubbed to return no grants.   Implement according to issue #1600
        []
      end

      # @api public
      #
      # Get a list of group that should be added as group editors for a new collection of the specified collection type
      #
      # @param collection_type [Hyrax::CollectionType] the type of the collection being created
      # @return [Array<String>] array of group identifiers (typically groupname) for groups who can edit collections of this type
      def self.group_edit_grants_for_collection_of_type(collection_type: nil)
        return [] unless collection_type
        # Stubbed to return no grants.   Implement according to issue #1600
        []
      end
    end
  end
end
