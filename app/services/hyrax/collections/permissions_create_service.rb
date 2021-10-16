# frozen_string_literal: true
module Hyrax
  module Collections
    class PermissionsCreateService
      class << self
        # @api public
        #
        # Set the default permissions for a (newly created) collection
        #
        # @param collection [#collection_type_gid || Hyrax::AdministrativeSet] the collection or admin set the new permissions will act on
        # @param creating_user [User] the user that created the collection
        # @param grants [Array<Hash>] additional grants to apply to the new collection
        # @return [Hyrax::PermissionTemplate]
        def create_default(collection:, creating_user:, grants: [])
          collection_type = collection_type(collection: collection)
          access_grants = access_grants_attributes(collection_type: collection_type, creating_user: creating_user, grants: grants)
          template = PermissionTemplate.create!(source_id: collection.id.to_s,
                                                access_grants_attributes: access_grants.uniq)

          template.reset_access_controls_for(collection: collection, interpret_visibility: true)
          template
        end

        # @api public
        #
        # Add access grants to a collection
        #
        # @param collection_id [String] id of a collection
        # @param grants [Array<Hash>] array of grants to add to the collection
        # @example grants
        #   [ { agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        #       agent_id: 'my_group_name',
        #       access: Hyrax::PermissionTemplateAccess::DEPOSIT } ]
        # @see Hyrax::PermissionTemplateAccess for valid values for agent_type and access
        def add_access(collection_id:, grants:)
          collection = Hyrax.query_service.find_by(id: collection_id)
          template = Hyrax::PermissionTemplate.find_by!(source_id: collection_id.to_s)
          grants.each do |grant|
            Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: template.id.to_s,
                                                              agent_type: grant[:agent_type],
                                                              agent_id: grant[:agent_id],
                                                              access: grant[:access])
          end

          template.reset_access_controls_for(collection: collection, interpret_visibility: true)
        end

        private

        # @api private
        #
        # Gather the default permissions needed for a new collection
        #
        # @param collection_type [CollectionType] the collection type of the new collection
        # @param creating_user [User] the user that created the collection
        # @param grants [Array<Hash>] additional grants to apply to the new collection
        # @return [Array<Hash>] a hash containing permission attributes
        def access_grants_attributes(collection_type:, creating_user:, grants:)
          [
            { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
          ].tap do |attribute_list|
            # Grant manage access to the creating_user if it exists
            attribute_list << { agent_type: 'user', agent_id: creating_user.user_key, access: Hyrax::PermissionTemplateAccess::MANAGE } if creating_user
          end + managers_of_collection_type(collection_type: collection_type) + grants
        end

        # @api private
        #
        # Retrieve the users or groups with manage permissions for a collection type
        #
        # @param collection_type [CollectionType] the collection type of the new collection
        # @return [Array<Hash>] a hash containing permission attributes
        def managers_of_collection_type(collection_type:)
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

        # @api private
        #
        # The value of the admin group name
        #
        # @return [String] a string representation of the admin group name
        def admin_group_name
          ::Ability.admin_group_name
        end

        # @api private
        #
        # The collection_type for the collection
        # @param collection [#collection_type_gid || Hyrax::AdministrativeSet] the collection or admin set the new permissions will act on
        # @return [Hyrax::CollectionType] a string representation of the admin group name
        def collection_type(collection:)
          return Hyrax::CollectionType.find_or_create_admin_set_type if admin_set? collection
          Hyrax::CollectionType.find_by_gid!(collection.collection_type_gid)
        end

        def admin_set?(collection)
          collection.is_a?(Hyrax::AdministrativeSet) || collection.is_a?(AdminSet)
        end
      end
    end
  end
end
