module Hyrax
  module Collections
    class PermissionsService
      # @api public
      #
      # Get a list of users who should be added as user editors for a collection
      #
      # @param collection [Hyrax::Collection] the collection for which permissions are being set
      # @return [Array<String>] array of user identifiers (typically emails) for users who can edit this collection
      def self.user_edit_grants_for_collection(collection: nil)
        return [] unless collection
        # Stubbed to return no grants
        []
      end

      # @api public
      #
      # Determine if the given user has permissions to deposit into the given collection
      #
      # @param user [User] the user that wants to deposit
      # @param collection [Hyrax::Collection] the collection we are checking permissions on
      # @return [Boolean] true if the user has permission to depoisit into the collection
      def self.can_deposit_in_collection(user:, collection:)
        return false unless user && collection
        # stubbed
      end

      # @api public
      #
      # Get a list of users who should be added as user viewers for a collection
      #
      # @param collection [Hyrax::Collection] the collection for which permissions are being set
      # @return [Array<String>] array of user identifiers (typically emails) for users who can view this collection
      def self.user_view_grants_for_collection(collection: nil)
        return [] unless collection
        # Stubbed to return no grants
        []
      end

      # @api public
      #
      # Get a list of groups that should be added as group editors for a collection
      #
      # @param collection [Hyrax::Collection] the collection for which permissions are being set
      # @return [Array<String>] array of group identifiers (typically groupname) for groups who can edit this collection
      def self.group_edit_grants_for_collection(collection: nil)
        return [] unless collection
        # Stubbed to return no grants
        []
      end

      # @api public
      #
      # Get a list of groups that should be added as group depositors for a collection
      #
      # @param collection [Hyrax::Collection] the collection for which permissions are being set
      # @return [Array<String>] array of group identifiers (typically groupname) for groups who can deposit to this collection
      def self.group_deposit_grants_for_collection(collection: nil)
        return [] unless collection
        # Stubbed to return no grants
        []
      end

      # @api public
      #
      # Get a list of groups that should be added as group viewers for a collection
      #
      # @param collection [Hyrax::Collection] the collection for which permissions are being set
      # @return [Array<String>] array of group identifiers (typically groupname) for groups who can view this collection
      def self.group_view_grants_for_collection(collection: nil)
        return [] unless collection
        # Stubbed to return no grants
        []
      end

      # @api public
      #
      # Set the default permissions for a (newly created) collection
      #
      # @param collection [Collection] the collection the new permissions will act on
      # @param creating_user [User] the user that created the collection
      # @return [Hyrax::PermissionTemplate]
      def self.create_default(collection:, creating_user:)
        collection_type = Hyrax::CollectionType.find_by_gid!(collection.collection_type_gid)
        access_grants = access_grants_attributes(collection_type: collection_type, creating_user: creating_user)
        PermissionTemplate.create!(source_id: collection.id, source_type: 'collection',
                                   access_grants_attributes: access_grants.uniq)
      end

      # @api private
      #
      # Gather the default permissions needed for a new collection
      #
      # @param collection_type [CollectionType] the collection type of the new collection
      # @param creating_user [User] the user that created the collection
      # @return [Hash] a hash containing permission attributes
      def self.access_grants_attributes(collection_type:, creating_user:)
        [
          { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
        ].tap do |attribute_list|
          # Grant manage access to the creating_user if it exists
          if creating_user
            attribute_list << { agent_type: 'user', agent_id: creating_user.user_key, access: Hyrax::PermissionTemplateAccess::MANAGE }
          end
        end + managers_of_collection_type(collection_type: collection_type)
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
