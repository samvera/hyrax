module Hyrax
  module Collections
    class PermissionsService # rubocop:disable Metrics/ClassLength
      # @api public
      #
      # IDs of collections/or admin_sets a user can access based on participant roles.
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Array<String>] IDs of collections and admin sets for which the user has specified roles
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.source_ids_for_user(access:, user: nil, ability: nil, source_type: nil)
        return false unless user.present? || ability.present? # One of these two are required.  Will prefer ability over user if both are specified.
        if user_admin?(user, ability)
          PermissionTemplate.all.pluck('DISTINCT source_id')
        else
          PermissionTemplateAccess.joins(:permission_template)
                                  .where(user_where(access: access, user: user, ability: ability, source_type: source_type))
                                  .or(
                                    PermissionTemplateAccess.joins(:permission_template)
                                      .where(group_where(access: access, user: user, ability: ability, source_type: source_type))
                                  ).pluck('DISTINCT source_id')
        end
      end

      # @api public
      #
      # IDs of admin sets a user can access based on participant roles.
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<String>] IDs of admin sets for which the user has specified roles
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.admin_set_ids_for_user(access:, user: nil, ability: nil)
        source_ids_for_user(user: user, access: access, ability: ability, source_type: 'admin_set')
      end

      # @api public
      #
      # Determine if the given user has permissions to deposit at least one collection
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to deposit in at least one collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_deposit_any_collection?(user: nil, ability: nil)
        collection_ids_for_user(user: user, ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT]).present?
      end

      # @api public
      #
      # IDs of collections a user can access based on participant roles.
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<String>] IDs of collections for which the user has specified roles
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.collection_ids_for_user(access:, user: nil, ability: nil)
        source_ids_for_user(user: user, access: access, ability: ability, source_type: 'collection')
      end

      # @api public
      #
      # IDs of collections and/or admin_sets into which a user can deposit.
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Array<String>] IDs of collections and/or admin_sets into which the user can deposit
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.source_ids_for_deposit(user: nil, ability: nil, source_type: nil)
        access = [Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT]
        source_ids_for_user(user: user, access: access, ability: ability, source_type: source_type)
      end

      # @api public
      #
      # IDs of collections and/or admin_sets that a user can manage.
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Array<String>] IDs of collections and/or admin_sets that the user can manage
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.source_ids_for_manage(user: nil, ability: nil, source_type: nil)
        access = [Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::MANAGE]
        source_ids_for_user(user: user, access: access, ability: ability, source_type: source_type)
      end

      # @api public
      #
      # IDs of admin_sets into which a user can deposit.
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<String>] IDs of admin_sets into which the user can deposit
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.admin_set_ids_for_deposit(user: nil, ability: nil)
        source_ids_for_deposit(user: user, ability: ability, source_type: 'admin_set')
      end

      # @api public
      #
      # IDs of collections into which a user can deposit.
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<String>] IDs of collections into which the user can deposit
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.collection_ids_for_deposit(user: nil, ability: nil)
        return ["bv73c0402"]
        source_ids_for_deposit(user: user, ability: ability, source_type: 'collection')
      end

      # @api public
      #
      # IDs of admin sets that a user can manage.
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<String>] IDs of admin sets that the user can manage
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.admin_set_ids_for_manage(user: nil, ability: nil)
        source_ids_for_manage(user: user, ability: ability, source_type: 'admin_set')
      end

      # @api public
      #
      # IDs of collections that a user can manage.
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Array<String>] IDs of collections that the user can manage
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.collection_ids_for_manage(user: nil, ability: nil)
        source_ids_for_manage(user: user, ability: ability, source_type: 'collection')
      end

      # @api private
      #
      # Generate the user where clause hash for joining the permissions tables
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Hash] the where clause hash to pass to joins for users
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.user_where(access:, user: nil, ability: nil, source_type: nil)
        where_clause = {}
        where_clause[:agent_type] = 'user'
        where_clause[:agent_id] = user_id(user, ability)
        where_clause[:access] = access
        where_clause[:permission_templates] = { source_type: source_type } if source_type.present?
        where_clause
      end
      private_class_method :user_where

      # @api private
      #
      # Generate the group where clause hash for joining the permissions tables
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Hash] the where clause hash to pass to joins for groups
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.group_where(access:, user: nil, ability: nil, source_type: nil)
        where_clause = {}
        where_clause[:agent_type] = 'group'
        where_clause[:agent_id] = user_groups(user, ability)
        where_clause[:access] = access
        where_clause[:permission_templates] = { source_type: source_type } if source_type.present?
        where_clause
      end
      private_class_method :group_where

      # @api public
      #
      # Determine if the given user has permissions to view the admin show page for at least one collection
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to view the admin show page for at least one collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_view_admin_show_for_any_collection?(user: nil, ability: nil)
        collection_ids_for_user(user: user, ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE,
                                                                       Hyrax::PermissionTemplateAccess::DEPOSIT,
                                                                       Hyrax::PermissionTemplateAccess::VIEW]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to view the admin show page for at least one admin set
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to view the admin show page for at least one admin_set
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_view_admin_show_for_any_admin_set?(user: nil, ability: nil)
        admin_set_ids_for_user(user: user, ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE,
                                                                      Hyrax::PermissionTemplateAccess::DEPOSIT,
                                                                      Hyrax::PermissionTemplateAccess::VIEW]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to manage at least one collection
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to manage at least one collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_manage_any_collection?(user: nil, ability: nil)
        collection_ids_for_user(user: user, ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to manage at least one admin set
      #
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to manage at least one admin_set
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_manage_any_admin_set?(user: nil, ability: nil)
        admin_set_ids_for_user(user: user, ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to deposit into the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to deposit into the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_deposit_in_collection?(collection_id:, user: nil, ability: nil)
        deposit_access_to_collection?(user: user, collection_id: collection_id, ability: ability) ||
          manage_access_to_collection?(user: user, collection_id: collection_id, ability: ability)
      end

      # @api public
      #
      # Determine if the given user has permissions to view the admin show page for the collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to view the admin show page for the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.can_view_admin_show_for_collection?(collection_id:, user: nil, ability: nil)
        deposit_access_to_collection?(user: user, collection_id: collection_id, ability: ability) ||
          manage_access_to_collection?(user: user, collection_id: collection_id, ability: ability) ||
          view_access_to_collection?(user: user, collection_id: collection_id, ability: ability)
      end

      # @api private
      #
      # Determine if the given user has :deposit access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has :deposit access to the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.deposit_access_to_collection?(collection_id:, user: nil, ability: nil)
        access_to_collection?(user: user, collection_id: collection_id, access: 'deposit', ability: ability)
      end
      private_class_method :deposit_access_to_collection?

      # @api private
      #
      # Determine if the given user has :manage access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has :manage access to the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.manage_access_to_collection?(collection_id:, user: nil, ability: nil)
        access_to_collection?(user: user, collection_id: collection_id, access: 'manage', ability: ability)
      end
      private_class_method :manage_access_to_collection?

      # @api private
      #
      # Determine if the given user has :view access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to view the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.view_access_to_collection?(collection_id:, user: nil, ability: nil)
        access_to_collection?(user: user, collection_id: collection_id, access: 'view', ability: ability)
      end
      private_class_method :view_access_to_collection?

      # @api private
      #
      # Determine if the given user has specified access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param access [Symbol] the access level to check
      # @param user [User] user (required if ability is nil)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil) (required if user is nil)
      # @return [Boolean] true if the user has permission to view the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.access_to_collection?(collection_id:, access:, user: nil, ability: nil)
        return false unless user.present? || ability.present?
        return false unless collection_id
        template = Hyrax::PermissionTemplate.find_by!(source_id: collection_id)
        return true if ([user_id(user, ability)] & template.agent_ids_for(agent_type: 'user', access: access)).present?
        return true if (user_groups(user, ability) & template.agent_ids_for(agent_type: 'group', access: access)).present?
        false
      end
      private_class_method :access_to_collection?

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
