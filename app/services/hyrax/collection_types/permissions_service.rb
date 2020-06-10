# frozen_string_literal: true
module Hyrax
  module CollectionTypes
    class PermissionsService
      # @api public
      #
      # Ids of collection types that a user can create or manage
      #
      # @param roles [String] type of access, Hyrax::CollectionTypeParticipant::MANAGE_ACCESS and/or Hyrax::CollectionTypeParticipant::CREATE_ACCESS
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<String>] ids for collection types for which a user has the specified role
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.collection_type_ids_for_user(roles:, user: nil, ability: nil)
        return false unless user.present? || ability.present?
        return Hyrax::CollectionType.all.select(:id).distinct.pluck(:id) if user_admin?(user, ability)
        Hyrax::CollectionTypeParticipant.where(agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE,
                                               agent_id: user_id(user, ability),
                                               access: roles)
                                        .or(
                                          Hyrax::CollectionTypeParticipant.where(agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                                                                 agent_id: user_groups(user, ability),
                                                                                 access: roles)
                                        )
                                        .select(:hyrax_collection_type_id)
                                        .distinct
                                        .pluck(:hyrax_collection_type_id)
      end

      # @api public
      #
      # Instances of collection types that a user can create or manage
      #
      # @param roles [String] type of access, Hyrax::CollectionTypeParticipant::MANAGE_ACCESS and/or Hyrax::CollectionTypeParticipant::CREATE_ACCESS
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<Hyrax::CollectionType>] instances of collection types for which a user has the specified role
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.collection_types_for_user(roles:, user: nil, ability: nil)
        return false unless user.present? || ability.present?
        return Hyrax::CollectionType.all if user_admin?(user, ability)
        Hyrax::CollectionType.where(id: collection_type_ids_for_user(user: user, roles: roles, ability: ability))
      end

      # @api public
      #
      # Is the user a creator for any collection types?
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to create collections of at least one collection type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_create_any_collection_type?(user: nil, ability: nil)
        return false unless user.present? || ability.present?
        return true if user_admin?(user, ability)
        # both manage and create access can create collections of a type, so no need to include access in the query
        return true if Hyrax::CollectionTypeParticipant.where(agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE,
                                                              agent_id: user_id(user, ability)).any?
        return true if Hyrax::CollectionTypeParticipant.where(agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                                              agent_id: user_groups(user, ability)).any?
        false
      end

      # @api public
      #
      # Is the user a creator for admin sets collection types?
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to create collections of type admin_set
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_create_admin_set_collection_type?(user: nil, ability: nil)
        return false unless user.present? || ability.present?
        return true if user_admin?(user, ability)
        # both manage and create access can create collections of a type, so no need to include access in the query
        return true if Hyrax::CollectionTypeParticipant.joins(:hyrax_collection_type)
                                                       .where(agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE,
                                                              agent_id: user_id(user, ability),
                                                              hyrax_collection_types: { machine_id: Hyrax::CollectionType::ADMIN_SET_MACHINE_ID }).present?
        return true if Hyrax::CollectionTypeParticipant.joins(:hyrax_collection_type)
                                                       .where(agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                                              agent_id: user_groups(user, ability),
                                                              hyrax_collection_types: { machine_id: Hyrax::CollectionType::ADMIN_SET_MACHINE_ID }).present?
        false
      end

      # @api public
      #
      # Get a list of collection types that a user can create
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<Hyrax::CollectionType>] array of collection types the user can create
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_create_collection_types(user: nil, ability: nil)
        collection_types_for_user(user: user, ability: ability, roles: [Hyrax::CollectionTypeParticipant::MANAGE_ACCESS, Hyrax::CollectionTypeParticipant::CREATE_ACCESS])
      end

      # @api public
      #
      # Get a list of collection types that a user can create
      #
      # @param collection_type [Hyrax::CollectionType] the type of the collection being created
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to create collections of specified type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_create_collection_of_type?(collection_type:, user: nil, ability: nil)
        manage_access_for_collection_type?(user: user, ability: ability, collection_type: collection_type) ||
          create_access_for_collection_type?(user: user, ability: ability, collection_type: collection_type)
      end

      # @api private
      #
      # Determine if the given user has :manage access for the given collection type
      #
      # @param collection_type [Hyrax::CollectionType] the collection type we are checking permissions on
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to manage collections of the specified collection type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.manage_access_for_collection_type?(collection_type:, user: nil, ability: nil)
        access_to_collection_type?(user: user, ability: ability, collection_type: collection_type, access: 'manage')
      end
      private_class_method :manage_access_for_collection_type?

      # @api private
      #
      # Determine if the given user has :create access for the given collection type
      #
      # @param collection_type [Hyrax::CollectionType] the collection type we are checking permissions on
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to create collections of the specified collection type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.create_access_for_collection_type?(collection_type:, user: nil, ability: nil)
        access_to_collection_type?(user: user, ability: ability, collection_type: collection_type, access: 'create')
      end
      private_class_method :create_access_for_collection_type?

      # @api private
      #
      # Determine if the given user has specified access for the given collection type
      #
      # @param collection_type [Hyrax::CollectionType] the collection type we are checking permissions on
      # @param access [Symbol] the access level to check
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to create collections of the specified collection type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.access_to_collection_type?(collection_type:, access:, user: nil, ability: nil) # rubocop:disable Metrics/CyclomaticComplexity
        return false unless user.present? || ability.present?
        return false unless user && collection_type
        return true if ([user_id(user, ability)] & agent_ids_for(collection_type: collection_type, agent_type: 'user', access: access)).present?
        return true if (user_groups(user, ability) & agent_ids_for(collection_type: collection_type, agent_type: 'group', access: access)).present?
        false
      end
      private_class_method :access_to_collection_type?

      # @api public
      #
      # What types of collection can the user create or manage
      #
      # @param user [User] user - The user requesting to create/manage a Collection
      # @param roles [String] type of access, Hyrax::CollectionTypeParticipant::MANAGE_ACCESS and/or Hyrax::CollectionTypeParticipant::CREATE_ACCESS
      # @return [Array<Hyrax::CollectionType>]
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.agent_ids_for(collection_type:, agent_type:, access:)
        Hyrax::CollectionTypeParticipant.where(hyrax_collection_type_id: collection_type.id,
                                               agent_type: agent_type,
                                               access: access).pluck(Arel.sql('DISTINCT agent_id'))
      end
      private_class_method :agent_ids_for

      # @api public
      #
      # Get a list of users who should be added as user editors for a new collection of the specified collection type
      #
      # @param collection_type [Hyrax::CollectionType] the type of the collection being created
      # @return [Array<String>] array of user identifiers (typically emails) for users who can edit collections of this type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.user_edit_grants_for_collection_of_type(collection_type: nil)
        return [] unless collection_type
        Hyrax::CollectionTypeParticipant.joins(:hyrax_collection_type).where(hyrax_collection_type_id: collection_type.id,
                                                                             agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE,
                                                                             access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS).pluck(Arel.sql('DISTINCT agent_id'))
      end

      # @api public
      #
      # Get a list of group that should be added as group editors for a new collection of the specified collection type
      #
      # @param collection_type [Hyrax::CollectionType] the type of the collection being created
      # @return [Array<String>] array of group identifiers (typically groupname) for groups who can edit collections of this type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.group_edit_grants_for_collection_of_type(collection_type: nil)
        return [] unless collection_type
        groups = Hyrax::CollectionTypeParticipant.joins(:hyrax_collection_type).where(hyrax_collection_type_id: collection_type.id,
                                                                                      agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                                                                      access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS).pluck(Arel.sql('DISTINCT agent_id'))
        groups | ['admin']
      end

      def self.user_groups(user, ability)
        # if called from abilities class, use ability instead of user; otherwise, you end up in an infinite loop
        return ability.user_groups if ability.present?
        user.ability.user_groups
      end
      private_class_method :user_groups

      def self.user_admin?(user, ability)
        # if called from abilities class, use ability instead of user; otherwise, you end up in an infinite loop
        return ability.admin? if ability.present?
        user.ability.admin?
      end
      private_class_method :user_groups

      def self.user_id(user, ability)
        return ability.current_user.user_key if ability.present?
        user.user_key
      end
      private_class_method :user_id
    end
  end
end
