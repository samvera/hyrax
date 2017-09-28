module Hyrax
  module Collections
    class PermissionsService
      # @api private
      #
      # IDs of collections, including admin sets, a user can access based on participant roles.
      #
      # @param user [User] user
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @return [Array<String>] IDs of collections for which the user has specified roles
      def self.collection_ids_for_user(user:, access:) # rubocop:disable Metrics/MethodLength
        if user.ability.admin?
          PermissionTemplate.all.where(source_type: 'collection').pluck('DISTINCT source_id')
        else
          PermissionTemplateAccess.joins(:permission_template)
                                  .where(agent_type: 'user',
                                         agent_id: user.user_key,
                                         access: access)
                                  .or(
                                    PermissionTemplateAccess.joins(:permission_template)
                                                            .where(agent_type: 'group',
                                                                   agent_id: user.groups,
                                                                   access: access)
                                  ).pluck('DISTINCT source_id')
        end
      end
      private_class_method :collection_ids_for_user

      # @api public
      #
      # IDs of collections, including admin sets, for which the user is assigned view access
      #
      # @param user [User]
      # @return [Array<String>] a list of collection ids for which the user is assigned view access
      def self.collection_ids_with_view_access(user:)
        return [] unless user
        collection_ids_for_user(user: user, access: [Hyrax::PermissionTemplateAccess::VIEW])
      end

      # @api public
      #
      # IDs of collections, including admin sets, for which the user is assigned manage access
      #
      # @param user [User]
      # @return [Array<String>] a list of collection ids for which the user is assigned manage access
      def self.collection_ids_with_manage_access(user:)
        return [] unless user
        collection_ids_for_user(user: user, access: [Hyrax::PermissionTemplateAccess::MANAGE])
      end

      # @api public
      #
      # IDs of collections, including admin sets, for which the user is assigned deposit access
      #
      # @param user [User]
      # @return [Array<String>] a list of collection ids for which the user is assigned deposit access
      def self.collection_ids_with_deposit_access(user:)
        return [] unless user
        collection_ids_for_user(user: user, access: [Hyrax::PermissionTemplateAccess::DEPOSIT])
      end

      # @api public
      #
      # IDs of collections, including admin sets, into which the user can deposit
      #
      # @param user [User] the user that wants to deposit
      # @return [Array<String>] a list of collection ids for collections in which the user can deposit
      def self.collection_ids_for_deposit(user:)
        return [] unless user
        collection_ids_for_user(user: user, access: [Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT])
      end

      # @api public
      #
      # Determine if the given user has permissions to deposit into the given collection
      #
      # @param user [User] the user that wants to deposit
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @return [Boolean] true if the user has permission to deposit into the collection
      def self.can_deposit_in_collection(user:, collection:)
        return false unless user && collection
        template = Hyrax::PermissionTemplate.find_by!(source_id: collection.id)
        return true if access_as_user?(user: user, template: template)
        return true if access_through_group?(groups: user.ability.user_groups, template: template)
        false
      end

      # @api private
      #
      # Does the user have 'manage' or 'deposit' access?
      #
      # @param user [User] the user that wants to deposit in the collection
      # @param template [PermissionTemplate] the permission template controlling access
      # @return [True | False] true, if user has access; otherwise, false
      def self.access_as_user?(user:, template:)
        return true if template.agent_ids_for(agent_type: 'user', access: 'manage').include? user.user_key
        return true if template.agent_ids_for(agent_type: 'user', access: 'deposit').include? user.user_key
        false
      end
      private_class_method :access_as_user?

      # @api private
      #
      # Do any of the groups have 'manage' or 'deposit' access?
      #
      # @param groups [Array<String>] the groups for the user that wants to deposit in the collection
      # @param template [PermissionTemplate] the permission template controlling access
      # @return [True | False] true, if any of the groups have access; otherwise, false
      def self.access_through_group?(groups:, template:)
        return false if groups.blank?
        return true if (groups & template.agent_ids_for(agent_type: 'group', access: 'manage')).present?
        return true if (groups & template.agent_ids_for(agent_type: 'group', access: 'deposit')).present?
        false
      end
      private_class_method :access_through_group?

      # @api public
      #
      # Set the default permissions for a (newly created) collection
      #
      # @param collection [Collection] the collection the new permissions will act on
      # @param creating_user [User] the user that created the collection
      # @param grants [Array<Hash>] additional grants to apply to the new collection
      # @return [Hyrax::PermissionTemplate]
      def self.create_default(collection:, creating_user:, grants: [])
        collection_type = Hyrax::CollectionType.find_by_gid!(collection.collection_type_gid)
        access_grants = access_grants_attributes(collection_type: collection_type, creating_user: creating_user, grants: grants)
        PermissionTemplate.create!(source_id: collection.id, source_type: 'collection',
                                   access_grants_attributes: access_grants.uniq)
        collection.update_access_controls!
      end

      # @api private
      #
      # Gather the default permissions needed for a new collection
      #
      # @param collection_type [CollectionType] the collection type of the new collection
      # @param creating_user [User] the user that created the collection
      # @param grants [Array<Hash>] additional grants to apply to the new collection
      # @return [Hash] a hash containing permission attributes
      def self.access_grants_attributes(collection_type:, creating_user:, grants:)
        [
          { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
        ].tap do |attribute_list|
          # Grant manage access to the creating_user if it exists
          if creating_user
            attribute_list << { agent_type: 'user', agent_id: creating_user.user_key, access: Hyrax::PermissionTemplateAccess::MANAGE }
          end
        end + managers_of_collection_type(collection_type: collection_type) + grants
      end
      private_class_method :access_grants_attributes

      # @api private
      #
      # Retrieve the users or groups with manage permissions for a collection type
      #
      # @param collection_type [CollectionType] the collection type of the new collection
      # @return [Hash] a hash containing permission attributes
      def self.managers_of_collection_type(collection_type:)
        attribute_list = []
        user_managers = Hyrax::CollectionTypes::PermissionsService.user_edit_grants_for_collection_of_type(collection_type: collection_type)
        user_managers.each do |user|
          attribute_list << { agent_type: 'user', agent_id: user, access: Hyrax::PermissionTemplateAccess::MANAGE }
        end
        group_managers = Hyrax::CollectionTypes::PermissionsService.group_edit_grants_for_collection_of_type(collection_type: collection_type)
        group_managers.each do |group|
          attribute_list << { agent_type: 'group', agent_id: group, access: Hyrax::PermissionTemplateAccess::MANAGE }
        end
        attribute_list
      end
      private_class_method :managers_of_collection_type

      # @api private
      #
      # The value of the admin group name
      #
      # @return [String] a string representation of the admin group name
      def self.admin_group_name
        ::Ability.admin_group_name
      end
      private_class_method :admin_group_name
    end
  end
end
