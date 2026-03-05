# frozen_string_literal: true
module Hyrax
  module Collections
    # rubocop:disable Metrics/ClassLength
    class PermissionsService
      # @api private
      #
      # IDs of collections/or admin_sets a user can access based on participant roles.
      #
      # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
      # @param ability [Ability] the ability coming from cancan ability check
      # @param source_type [String] 'collection', 'admin_set', or nil to get all types
      # @param exclude_groups [Array<String>] name of groups to exclude from the results
      # @return [Array<String>] IDs of collections and admin sets for which the user has specified roles
      def self.source_ids_for_user(access:, ability:, source_type: nil, exclude_groups: [])
        scope = PermissionTemplateAccess.for_user(ability: ability, access: access, exclude_groups: exclude_groups)
                                        .joins(:permission_template)
        ids = scope.select(:source_id).distinct.pluck(:source_id)
        return ids unless source_type
        filter_source(source_type: source_type, ids: ids)
      end
      private_class_method :source_ids_for_user

      # rubocop:disable Metrics/MethodLength
      def self.filter_source(source_type:, ids:)
        return [] if ids.empty?
        models = case source_type
                 when 'admin_set'
                   Hyrax::ModelRegistry.admin_set_classes
                 when 'collection'
                   Hyrax::ModelRegistry.collection_classes
                 end

        # Antics to cope with all of the how the custom queries work.
        if defined?(Wings::ModelRegistry)
          models = models.map do |model|
            Wings::ModelRegistry.reverse_lookup(model)
                   rescue NoMethodError
                     nil
          end.compact
        end

        models.flat_map do |model|
          if model
            Hyrax.custom_queries.find_ids_by_model(model: model, ids: ids).to_a
          else
            []
          end
        end.uniq
      end
      # rubocop:enable Metrics/MethodLength
      private_class_method :filter_source

      # @api private
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
      private_class_method :admin_set_ids_for_user

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
      # @param exclude_groups [Array<String>] name of groups to exclude from the results
      # @return [Array<String>] IDs of collections and/or admin_sets into which the user can deposit
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.source_ids_for_deposit(ability:, source_type: nil, exclude_groups: [])
        access = [Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT]
        source_ids_for_user(access: access, ability: ability, source_type: source_type, exclude_groups: exclude_groups)
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
      # IDs of collections which the user can view.
      #
      # @param ability [Ability] the ability coming from cancan ability check
      # @return [Array<String>] IDs of collections into which the user can view
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.collection_ids_for_view(ability:)
        collection_ids_for_user(ability: ability, access: [Hyrax::PermissionTemplateAccess::MANAGE,
                                                           Hyrax::PermissionTemplateAccess::DEPOSIT,
                                                           Hyrax::PermissionTemplateAccess::VIEW])
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
      # TODO: MOVE TO ABILITY
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
      # TODO: MOVE TO ABILITY

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
        exclude_groups = [::Ability.registered_group_name,
                          ::Ability.public_group_name]
        manage_access_to_collection?(collection_id: collection_id, ability: ability) ||
          deposit_access_to_collection?(collection_id: collection_id, ability: ability, exclude_groups: exclude_groups) ||
          view_access_to_collection?(collection_id: collection_id, ability: ability, exclude_groups: exclude_groups)
      end

      # @api private
      #
      # Determine if the given user has :deposit access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @param exclude_groups [Array<String>] name of groups to exclude from the results
      # @return [Boolean] true if the user has :deposit access to the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.deposit_access_to_collection?(collection_id:, ability: nil, exclude_groups: [])
        access_to_collection?(collection_id: collection_id, access: 'deposit', ability: ability, exclude_groups: exclude_groups)
      end
      private_class_method :deposit_access_to_collection?

      # @api public
      #
      # Determine if the given user has :manage access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @param exclude_groups [Array<String>] name of groups to exclude from the results
      # @return [Boolean] true if the user has :manage access to the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.manage_access_to_collection?(collection_id:, ability:, exclude_groups: [])
        access_to_collection?(collection_id: collection_id, access: 'manage', ability: ability, exclude_groups: exclude_groups)
      end

      # @api private
      #
      # Determine if the given user has :view access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param ability [Ability] the ability coming from cancan ability check
      # @param exclude_groups [Array<String>] name of groups to exclude from the results
      # @return [Boolean] true if the user has permission to view the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.view_access_to_collection?(collection_id:, ability:, exclude_groups: [])
        access_to_collection?(collection_id: collection_id, access: 'view', ability: ability, exclude_groups: exclude_groups)
      end
      private_class_method :view_access_to_collection?

      # @api private
      #
      # Determine if the given user has specified access for the given collection
      #
      # @param collection_id [String] id of the collection we are checking permissions on
      # @param access [Symbol] the access level to check
      # @param ability [Ability] the ability coming from cancan ability check
      # @param exclude_groups [Array<String>] name of groups to exclude from the results
      # @return [Boolean] true if the user has permission to view the collection
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      def self.access_to_collection?(collection_id:, access:, ability:, exclude_groups: [])
        return false unless collection_id
        template = Hyrax::PermissionTemplate.find_by!(source_id: collection_id.to_s)
        return true if ([ability.current_user.user_key] & template.agent_ids_for(agent_type: 'user', access: access)).present?
        return true if (ability.user_groups & (template.agent_ids_for(agent_type: 'group', access: access) - exclude_groups)).present?
        false
      end
      private_class_method :access_to_collection?
    end
    # rubocop:enable Metrics/ClassLength
  end
end
