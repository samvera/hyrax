module Hyrax
  module CollectionTypes
    class PermissionsService
      # @api public
      #
      # What types of collection can the user create or manage
      #
      # @param user [User] user - The user requesting to create/manage a Collection
      # @param roles [String] type of access, Hyrax::CollectionTypeParticipant::MANAGE_ACCESS and/or Hyrax::CollectionTypeParticipant::CREATE_ACCESS
      # @return [Array<Hyrax::CollectionType>]
      def self.collection_types_for_user(user:, roles:)
        return Hyrax::CollectionType.all if user.ability.admin?
        ids = Hyrax::CollectionTypeParticipant.where(agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE,
                                                     agent_id: user.user_key,
                                                     access: roles)
                                              .or(
                                                Hyrax::CollectionTypeParticipant.where(agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                                                                       agent_id: user.ability.user_groups,
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
        collection_types_for_user(user: user, roles: [Hyrax::CollectionTypeParticipant::MANAGE_ACCESS, Hyrax::CollectionTypeParticipant::CREATE_ACCESS])
      end

      # @api public
      #
      # Get a list of users who should be added as user editors for a new collection of the specified collection type
      #
      # @param collection_type [Hyrax::CollectionType] the type of the collection being created
      # @return [Array<String>] array of user identifiers (typically emails) for users who can edit collections of this type
      def self.user_edit_grants_for_collection_of_type(collection_type: nil)
        return [] unless collection_type
        Hyrax::CollectionTypeParticipant.joins(:hyrax_collection_type).where(hyrax_collection_type_id: collection_type.id,
                                                                             agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE,
                                                                             access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS).pluck('DISTINCT agent_id')
      end

      # @api public
      #
      # Get a list of group that should be added as group editors for a new collection of the specified collection type
      #
      # @param collection_type [Hyrax::CollectionType] the type of the collection being created
      # @return [Array<String>] array of group identifiers (typically groupname) for groups who can edit collections of this type
      def self.group_edit_grants_for_collection_of_type(collection_type: nil)
        return [] unless collection_type
        groups = Hyrax::CollectionTypeParticipant.joins(:hyrax_collection_type).where(hyrax_collection_type_id: collection_type.id,
                                                                                      agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                                                                      access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS).pluck('DISTINCT agent_id')
        groups | ['admin']
      end
    end
  end
end
