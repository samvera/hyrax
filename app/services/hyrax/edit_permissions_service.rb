# frozen_string_literal: true
module Hyrax
  class EditPermissionsService
    # Encapsulates the logic to determine which object permissions may be edited by a given user
    #  - user is permitted to update any work permissions coming ONLY from collections they manage
    #  - user is not permitted to update a work permission if it comes from a collection they do not manage, even if also from a managed collection
    #  - user is permitted to update only non-manager permissions from any Collections
    #  - user is permitted to update any non-collection permissions
    attr_reader :depositor, :unauthorized_collection_managers

    # @param [Object] GenericWorkForm (if called for object) or GenericWork (if called for file set)
    # @param [Ability] user's current_ability
    def initialize(object:, ability:)
      @object = object
      @ability = ability
      @depositor = object.depositor
      unauthorized = manager_permissions_to_block
      @unauthorized_managers = unauthorized.unauthorized_managers
      @unauthorized_collection_managers = unauthorized.unauthorized_collection_managers
    end

    # @param [Hash] one set of permission fields for object {:name, :access}
    # @return [Boolean] true if user cannot edit the given permissions
    def cannot_edit_permissions?(permission_hash)
      @unauthorized_managers.include?(permission_hash[:name]) && permission_hash[:access] == "edit"
    end

    # @param [Hash] one set of permission fields for object {:name, :access}
    # @return [Boolean] true if given permissions are one of fixed exclusions
    def excluded_permission?(permission_hash)
      exclude_from_display.include? permission_hash[:name].downcase
    end

    private

    # Fixed set of users & groups to exclude from "editable" section of display
    def exclude_from_display
      [::Ability.public_group_name, ::Ability.registered_group_name, ::Ability.admin_group_name, @depositor]
    end

    BlockedPermissions = Struct.new(:unauthorized_managers, :unauthorized_collection_managers)

    # find all of the other managers of collections which a user cannot manage
    #
    #   Process used:
    #   - find all of the work's collections which a user can manage
    #   - find all of the work's collections (of a type which shares permissions) that a user cannot manage
    #   - find all of the managers of these collections the user cannot manage
    #   This gives us the manager permissions the user is not authorized to update.
    #
    # @return [Struct] BlockedPermissions
    #   - unauthorized_managers [Array] ids of managers of all collections
    #   - unauthorized_collection_managers [Array hashes] manager ids & collection_ids [{:name, :id}]
    def manager_permissions_to_block
      unauthorized_managers = []
      unauthorized_collection_managers = []
      if object_unauthorized_collection_ids.any?
        object_unauthorized_collection_ids.each do |id|
          Hyrax::PermissionTemplate.find_by(source_id: id).access_grants.each do |grant|
            if grant.access == "manage"
              unauthorized_managers << grant.agent_id
              unauthorized_collection_managers += Array.wrap({ name: grant.agent_id }.merge(id: id))
            end
          end
        end
      end
      BlockedPermissions.new(unauthorized_managers, unauthorized_collection_managers)
    end

    # find all of the work's collections a user can manage
    # @return [Array] of collection ids
    def object_managed_collection_ids
      @object_managed_collection_ids ||= object_member_of & managed_collection_ids
    end

    # find all of the work's collections a user cannot manage
    # note: if the collection type doesn't include "sharing_applies_to_new_works", we don't limit access
    # @return [Array] of collection ids with limited access
    def object_unauthorized_collection_ids
      @object_unauthorized_collection_ids ||= begin
                                                limited_access = []
                                                unauthorized_collection_ids = object_member_of - object_managed_collection_ids
                                                if unauthorized_collection_ids.any?
                                                  unauthorized_collection_ids.each do |id|
                                                    collection = ActiveFedora::Base.find(id)
                                                    limited_access << id if (collection.instance_of? AdminSet) || collection.share_applies_to_new_works?
                                                  end
                                                end
                                                limited_access
                                              end
    end

    # find all of the collection ids an object is a member of
    # @return [Array] array of collection ids
    def object_member_of
      @object_member_of ||= begin
                              belongs_to = []
                              # get all of work's collection ids from the form
                              @object.member_of_collections.each do |collection|
                                belongs_to << collection.id
                              end
                              belongs_to << @object.admin_set_id unless @object.admin_set_id.empty?
                              belongs_to
                            end
    end

    # The list of all collections this user has manage rights on
    # @return [Array] array of all collection ids that user can manage
    def managed_collection_ids
      Hyrax::Collections::PermissionsService.source_ids_for_manage(ability: @ability)
    end
  end
end
