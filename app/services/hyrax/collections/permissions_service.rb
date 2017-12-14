module Hyrax
  module Collections
    class PermissionsService # rubocop:disable Metrics/ClassLength
      # @api private
      #
      # IDs of collections/or admin_sets a user can access based on participant roles.
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param ability [Ability] the ability coming from cancan ability check
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Array<String>] IDs of collections and admin sets for which the user has specified roles
      def self.source_ids_for_user(access:, ability:, source_type: nil)
        scope = PermissionTemplateAccess.for_user(ability: ability, access: access)
                                        .joins(:permission_template)
        scope = scope.where(permission_templates: { source_type: source_type }) if source_type
        scope.pluck('DISTINCT source_id')
      end
      private_class_method :source_ids_for_user

      # @api public
      #
      # IDs of admin sets a user can access based on participant roles.
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Array<String>] IDs of admin sets for which the user has specified roles
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.admin_set_ids_for_user(access:, ability:)
        source_ids_for_user(access: access, ability: ability, source_type: 'admin_set')
      end

      # @api public
      #
      # IDs of collections a user can access based on participant roles.
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Array<String>] IDs of collections for which the user has specified roles
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.collection_ids_for_user(access:, ability:)
        source_ids_for_user(access: access, ability: ability, source_type: 'collection')
      end

      # @api public
      #
      # IDs of collections and/or admin_sets into which a user can deposit.
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Array<String>] IDs of collections and/or admin_sets into which the user can deposit
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.source_ids_for_deposit(ability:, source_type: nil)
        access = [Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT]
        source_ids_for_user(access: access, ability: ability, source_type: source_type)
      end

      # @api public
      #
      # IDs of collections and/or admin_sets that a user can manage.
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Array<String>] IDs of collections and/or admin_sets that the user can manage
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.source_ids_for_manage(ability:, source_type: nil)
        access = [Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::MANAGE]
        source_ids_for_user(access: access, ability: ability, source_type: source_type)
      end

      # @api public
      #
      # IDs of admin_sets into which a user can deposit.
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Array<String>] IDs of admin_sets into which the user can deposit
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.admin_set_ids_for_deposit(ability:)
        source_ids_for_deposit(ability: ability, source_type: 'admin_set')
      end

      # @api public
      #
      # IDs of collections into which a user can deposit.
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Array<String>] IDs of collections into which the user can deposit
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.collection_ids_for_deposit(ability:)
        source_ids_for_deposit(ability: ability, source_type: 'collection')
      end

      # @api public
      #
      # IDs of admin sets that a user can manage.
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Array<String>] IDs of admin sets that the user can manage
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.admin_set_ids_for_manage(ability:)
        source_ids_for_manage(ability: ability, source_type: 'admin_set')
      end

      # @api public
      #
      # IDs of collections that a user can manage.
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Array<String>] IDs of collections that the user can manage
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.collection_ids_for_manage(ability:)
        source_ids_for_manage(ability: ability, source_type: 'collection')
      end

      # @api public
      #
      # Determine if the given user has permissions to view the admin show page for at least one collection
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to view the admin show page for at least one collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.can_view_admin_show_for_any_collection?(ability:)
        collection_ids_for_user(ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE,
                                                           Hyrax::PermissionTemplateAccess::DEPOSIT,
                                                           Hyrax::PermissionTemplateAccess::VIEW]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to view the admin show page for at least one admin set
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to view the admin show page for at least one admin_set
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.can_view_admin_show_for_any_admin_set?(ability:)
        admin_set_ids_for_user(ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE,
                                                          Hyrax::PermissionTemplateAccess::DEPOSIT,
                                                          Hyrax::PermissionTemplateAccess::VIEW]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to manage at least one collection
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to manage at least one collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.can_manage_any_collection?(ability:)
        collection_ids_for_user(ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to manage at least one admin set
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to manage at least one admin_set
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.can_manage_any_admin_set?(ability:)
        admin_set_ids_for_user(ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE]).present?
      end

      # @api public
      #
      # Determine if the given user has permissions to deposit into the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to deposit into the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.can_deposit_in_collection?(collection_id:, ability:)
        deposit_access_to_collection?(collection_id: collection_id, ability: ability) ||
          manage_access_to_collection?(collection_id: collection_id, ability: ability)
      end

      # @api public
      #
      # Determine if the given user has permissions to view the admin show page for the collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to view the admin show page for the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.can_view_admin_show_for_collection?(collection_id:, ability:)
        deposit_access_to_collection?(collection_id: collection_id, ability: ability) ||
          manage_access_to_collection?(collection_id: collection_id, ability: ability) ||
          view_access_to_collection?(collection_id: collection_id, ability: ability)
      end

      # @api private
      #
      # Determine if the given user has :deposit access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has :deposit access to the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.deposit_access_to_collection?(collection_id:, ability: nil)
        access_to_collection?(collection_id: collection_id, access: 'deposit', ability: ability)
      end
      private_class_method :deposit_access_to_collection?

      # @api private
      #
      # Determine if the given user has :manage access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has :manage access to the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.manage_access_to_collection?(collection_id:, ability:)
        access_to_collection?(collection_id: collection_id, access: 'manage', ability: ability)
      end
      private_class_method :manage_access_to_collection?

      # @api private
      #
      # Determine if the given user has :view access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to view the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.view_access_to_collection?(collection_id:, ability:)
        access_to_collection?(collection_id: collection_id, access: 'view', ability: ability)
      end
      private_class_method :view_access_to_collection?

      # @api private
      #
      # Determine if the given user has specified access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param access [Symbol] the access level to check
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Boolean] true if the user has permission to view the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.access_to_collection?(collection_id:, access:, ability:)
        return false unless collection_id
        template = Hyrax::PermissionTemplate.find_by!(source_id: collection_id)
        return true if ([ability.current_user.user_key] & template.agent_ids_for(agent_type: 'user', access: access)).present?
        return true if (ability.user_groups & template.agent_ids_for(agent_type: 'group', access: access)).present?
        false
      end
      private_class_method :access_to_collection?
    end
  end
end
