module Hyrax
  module Collections
    class PermissionsService
      # @api public
      #
      # IDs of admin sets a user can access based on participant roles.
      #
      # @param user [User] user
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Array<String>] IDs of admin sets for which the user has specified roles
      def self.admin_set_ids_for_user(user:, access:, ability: nil)
        if user_admin?(user, ability)
          PermissionTemplate.all.where(source_type: 'admin_set').pluck('DISTINCT source_id')
        else
          PermissionTemplateAccess.joins(:permission_template)
                                  .where(user_where(user: user, access: access, source_type: 'admin_set'))
                                  .or(
                                    PermissionTemplateAccess.joins(:permission_template)
                                                            .where(group_where(user: user, access: access, source_type: 'admin_set', ability: ability))
                                  ).pluck('DISTINCT source_id')
        end
      end

      # @api public
      #
      # IDs of collections a user can access based on participant roles.
      #
      # @param user [User] user
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Array<String>] IDs of collections for which the user has specified roles
      def self.collection_ids_for_user(user:, access:, ability: nil)
        if user_admin?(user, ability)
          PermissionTemplate.all.where(source_type: 'collection').pluck('DISTINCT source_id')
        else
          PermissionTemplateAccess.joins(:permission_template)
                                  .where(user_where(user: user, access: access, source_type: 'collection'))
                                  .or(
                                    PermissionTemplateAccess.joins(:permission_template)
                                                            .where(group_where(user: user, access: access, source_type: 'collection', ability: ability))
                                  ).pluck('DISTINCT source_id')
        end
      end

      # @api public
      #
      # IDs of collections and admin_sets a user can access based on participant roles.
      #
      # @param user [User] user
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Array<String>] IDs of collections and admin sets for which the user has specified roles
      def self.source_ids_for_user(user:, access:, ability: nil)
        if user_admin?(user, ability)
          PermissionTemplate.all.pluck('DISTINCT source_id')
        else
          PermissionTemplateAccess.joins(:permission_template)
                                  .where(user_where(user: user, access: access))
                                  .or(
                                    PermissionTemplateAccess.joins(:permission_template)
                                                            .where(group_where(user: user, access: access, ability: ability))
                                  ).pluck('DISTINCT source_id')
        end
      end

      # @api private
      #
      # Generate the user where clause hash for joining the permissions tables
      #
      # @param user [User] the user wanting access
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @return [Hash] the where clause hash to pass to joins for users
      def self.user_where(user:, access:, source_type: nil)
        where_clause = {}
        where_clause[:agent_type] = 'user'
        where_clause[:agent_id] = user.user_key
        where_clause[:access] = access
        where_clause[:permission_templates] = { source_type: source_type } if source_type.present?
        where_clause
      end
      private_class_method :user_where

      # @api private
      #
      # Generate the group where clause hash for joining the permissions tables
      #
      # @param user [User] the user wanting access
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Hash] the where clause hash to pass to joins for groups
      def self.group_where(user:, access:, source_type: nil, ability: nil)
        where_clause = {}
        where_clause[:agent_type] = 'group'
        where_clause[:agent_id] = user_groups(user, ability)
        where_clause[:access] = access
        where_clause[:permission_templates] = { source_type: source_type } if source_type.present?
        where_clause
      end
      private_class_method :user_where

      # @api public
      #
      # Determine if the given user has permissions to deposit into the given collection
      #
      # @param user [User] the user that wants to deposit
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Boolean] true if the user has permission to deposit into the collection
      def self.can_deposit_in_collection?(user:, collection:, ability: nil)
        deposit_access_to_collection?(user: user, collection: collection, ability: ability) ||
          manage_access_to_collection?(user: user, collection: collection, ability: ability)
      end

      # @api public
      #
      # Determine if the given user has permissions to view the admin show page for the collection
      #
      # @param user [User] the user that wants to view
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Boolean] true if the user has permission to view the admin show page for the collection
      def self.can_view_admin_show_for_collection?(user:, collection:, ability: nil)
        deposit_access_to_collection?(user: user, collection: collection, ability: ability) ||
          manage_access_to_collection?(user: user, collection: collection, ability: ability) ||
          view_access_to_collection?(user: user, collection: collection, ability: ability)
      end

      # @api private
      #
      # Determine if the given user has :deposit access for the given collection
      #
      # @param user [User] the user who wants to deposit
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Boolean] true if the user has :deposit access to the collection
      def self.deposit_access_to_collection?(user:, collection:, ability: nil)
        access_to_collection?(user: user, collection: collection, access: 'deposit', ability: ability)
      end
      private_class_method :deposit_access_to_collection?

      # @api private
      #
      # Determine if the given user has :manage access for the given collection
      #
      # @param user [User] the user who wants to manage
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Boolean] true if the user has :manage access to the collection
      def self.manage_access_to_collection?(user:, collection:, ability: nil)
        access_to_collection?(user: user, collection: collection, access: 'manage', ability: ability)
      end
      private_class_method :manage_access_to_collection?

      # @api private
      #
      # Determine if the given user has :view access for the given collection
      #
      # @param user [User] the user who wants to view
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Boolean] true if the user has permission to view the collection
      def self.view_access_to_collection?(user:, collection:, ability: nil)
        access_to_collection?(user: user, collection: collection, access: 'view', ability: ability)
      end
      private_class_method :view_access_to_collection?

      # @api private
      #
      # Determine if the given user has specified access for the given collection
      #
      # @param user [User] the user who wants to view
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @param access [Symbol] the access level to check
      # @param ability [Ability] the ability coming from cancan ability check (default: nil)
      # @return [Boolean] true if the user has permission to view the collection
      def self.access_to_collection?(user:, collection:, access:, ability: nil)
        return false unless user && collection
        template = Hyrax::PermissionTemplate.find_by!(source_id: collection.id)
        return true if (user_id(user) & template.agent_ids_for(agent_type: 'user', access: access)).present?
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

      def self.user_id(user)
        [user.user_key]
      end
      private_class_method :user_id
    end
  end
end
