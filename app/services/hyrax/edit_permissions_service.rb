# frozen_string_literal: true
module Hyrax
  # Encapsulates the logic to determine which object permissions may be edited by a given user
  #  - user is permitted to update any work permissions coming ONLY from collections they manage
  #  - user is not permitted to update a work permission if it comes from a collection they do not manage, even if also from a managed collection
  #  - user is permitted to update only non-manager permissions from any Collections
  #  - user is permitted to update any non-collection permissions
  class EditPermissionsService
    # @api public
    # @since v3.0.0
    #
    # @param form [SimpleForm::FormBuilder]
    # @param current_ability [Ability]
    # @return [Hyrax::EditPermissionService]
    #
    # @note
    #   form object.class = SimpleForm::FormBuilder
    #     For works (i.e. GenericWork):
    #     - form object.object = Hyrax::GenericWorkForm
    #     - form object.object.model = GenericWork
    #     - use the work itself
    #     For file_sets:
    #     - form object.object.class = FileSet
    #     - use work the file_set is in
    #     No other object types are supported by this view. %>
    def self.build_service_object_from(form:, ability:)
      if form.object.respond_to?(:model) && form.object.model.work?
        new(object: form.object, ability: ability)
      elsif form.object.file_set?
        new(object: form.object.in_works.first, ability: ability)
      end
    end

    attr_reader :depositor, :unauthorized_collection_managers

    # @param object [#depositor, #admin_set_id, #member_of_collection_ids] GenericWorkForm (if called for object) or GenericWork (if called for file set)
    # @param ability [Ability] user's current_ability
    def initialize(object:, ability:)
      @object = object
      @ability = ability
      @depositor = object.depositor
      unauthorized = manager_permissions_to_block
      @unauthorized_managers = unauthorized.unauthorized_managers
      @unauthorized_collection_managers = unauthorized.unauthorized_collection_managers
    end

    # @api private
    # @todo refactor this code to use "can_edit?"; Thinking in negations can be challenging.
    #
    # @param permission_hash [Hash] one set of permission fields for object {:name, :access}
    # @return [Boolean] true if user cannot edit the given permissions
    def cannot_edit_permissions?(permission_hash)
      permission_hash.fetch(:access) == "edit" && @unauthorized_managers.include?(permission_hash.fetch(:name))
    end

    # @api private
    #
    # @param permission_hash [Hash] one set of permission fields for object {:name, :access}
    # @return [Boolean] true if given permissions are one of fixed exclusions
    def excluded_permission?(permission_hash)
      exclude_from_display.include? permission_hash.fetch(:name).downcase
    end

    # @api public
    #
    # This method either:
    #
    # * returns false if the given permission_hash is part of the fixed exclusions.
    # * yields a PermissionPresenter to provide additional logic and text for rendering
    #
    # @param permission_hash [Hash<:name, :access>]
    # @return false if the given permission_hash is a fixed exclusion
    # @yield PermissionPresenter
    #
    # @see #excluded_permission?
    def with_applicable_permission(permission_hash:)
      return false if excluded_permission?(permission_hash)
      yield(PermissionPresenter.new(service: self, permission_hash: permission_hash))
    end

    # @api private
    #
    # A helper class to contain specific presentation logic related to
    # the EditPermissionsService
    class PermissionPresenter
      # @param service [Hyrax::EditPermissionsService]
      # @param permission_hash [Hash]
      def initialize(service:, permission_hash:)
        @service = service
        @permission_hash = permission_hash
      end

      # A hint at how permissions are granted.
      #
      # @return String
      # rubocop:disable Rails/OutputSafety
      def granted_by_html_hint
        html = ""
        @service.unauthorized_collection_managers.each do |managers|
          next unless name == managers.fetch(:name)
          html += "<br />Access granted via collection #{managers.fetch(:id)}"
        end
        html.html_safe
      end
      # rubocop:enable Rails/OutputSafety

      # @return String
      def name
        @permission_hash.fetch(:name)
      end

      # @return String
      def access
        @permission_hash.fetch(:access)
      end

      # @return Boolean
      # @see EditPermissionsService#cannot_edit_permissions?
      def can_edit?
        !@service.cannot_edit_permissions?(@permission_hash)
      end
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
      object_unauthorized_collection_ids.each do |id|
        Hyrax::PermissionTemplate.find_by(source_id: id).access_grants.each do |grant|
          if grant.access == "manage"
            unauthorized_managers << grant.agent_id
            unauthorized_collection_managers += Array.wrap({ name: grant.agent_id }.merge(id: id))
          end
        end
      end
      BlockedPermissions.new(unauthorized_managers, unauthorized_collection_managers)
    end

    # find all of the work's collections a user can manage
    # @return [Array] of collection ids
    def object_managed_collection_ids
      @object_managed_collection_ids ||= object_member_of_ids & managed_collection_ids
    end

    # find all of the work's collections a user cannot manage note: if
    # the collection type doesn't include
    # "sharing_applies_to_new_works", we don't limit access
    #
    # @return [Array] of collection ids with limited access
    #
    # @todo Refactor code to remove explicit ActiveFedora::Base call (see method implementation for details)
    def object_unauthorized_collection_ids
      @object_unauthorized_collection_ids ||= begin
                                                limited_access = []
                                                unauthorized_collection_ids = object_member_of_ids - object_managed_collection_ids
                                                unauthorized_collection_ids.each do |id|
                                                  # TODO: Refactor to remove ActiveFedora::Base
                                                  #
                                                  # Option 1: use `Hyrax.query_service.find_many_by_ids`.  This requires
                                                  #           some further adjustments.
                                                  #
                                                  #           A) The collection.share_applies_to_new_works? is a delegate method
                                                  #              on the Collection object to the associated Collection Type.  That does not exist on the
                                                  #              Valkyrie resource
                                                  #              (see https://github.com/samvera/hyrax/blob/696da5db/spec/models/collection_spec.rb#L189)
                                                  #           B) The `instance_of? AdminSet` will not work because there is an AdminSet object and a
                                                  #              Hyrax::AdministrativeSet class.
                                                  #
                                                  #           (Jeremy here) I had attempted this refactor, but I think that I need to discuss this with the
                                                  #           tech lead regarding approach.
                                                  #
                                                  # Option 2: use a Solr query; we would need to verify that the SOLR object for the collection has the
                                                  #           share_applies_to_new_works property (again, this is a delegate method from the collection
                                                  #           object to the collection type); We'd also need to account for AdminSet and
                                                  #           Hyrax::AdministrativeSet.
                                                  collection = ActiveFedora::Base.find(id)
                                                  limited_access << id if (collection.instance_of? AdminSet) || collection.share_applies_to_new_works?
                                                end
                                                limited_access
                                              end
    end

    # find all of the collection ids an object is a member of
    # @return [Array] array of collection ids
    def object_member_of_ids
      @object_member_of_ids ||= (@object.member_of_collection_ids + [@object.admin_set_id]).select(&:present?)
    end

    # The list of all collections this user has manage rights on
    # @return [Array] array of all collection ids that user can manage
    def managed_collection_ids
      Hyrax::Collections::PermissionsService.source_ids_for_manage(ability: @ability)
    end
  end
end
