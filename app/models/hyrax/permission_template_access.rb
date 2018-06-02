# frozen_string_literal: true

module Hyrax
  # Models a single grant of access to an agent (user or group) on a PermissionTemplate
  class PermissionTemplateAccess < ActiveRecord::Base
    self.table_name = 'permission_template_accesses'
    belongs_to :permission_template

    # An agent should only have any particular level of access once.
    validates :access, uniqueness: {
      scope: [:agent_id, :agent_type, :permission_template_id]
    }

    VIEW = 'view'
    DEPOSIT = 'deposit'
    MANAGE = 'manage'

    GROUP = 'group'
    USER = 'user'

    enum(
      access: {
        VIEW => VIEW,
        DEPOSIT => DEPOSIT,
        MANAGE => MANAGE
      }
    )

    # @api public
    #
    # The permissions template access a given user has.
    #
    # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
    # @param ability [Ability] the ability coming from cancan ability check
    # @param exclude_groups [Array<String>] name of groups to exclude from the results
    # @return [ActiveRecord::Relation] relation of templates for which the user has specified roles
    def self.for_user(ability:, access:, exclude_groups: [])
      PermissionTemplateAccess.where(
        user_where(access: access, ability: ability)
      ).or(
        PermissionTemplateAccess
          .where(group_where(access: access, ability: ability, exclude_groups: exclude_groups))
      )
    end

    def label
      return agent_id unless agent_type == GROUP
      case agent_id
      when 'registered'
        I18n.t('hyrax.admin.admin_sets.form_participant_table.registered_users')
      when ::Ability.admin_group_name
        I18n.t('hyrax.admin.admin_sets.form_participant_table.admin_users')
      else
        agent_id
      end
    end

    def admin_group?
      agent_type == GROUP && agent_id == ::Ability.admin_group_name
    end

    # @api private
    #
    # Generate the user where clause hash for joining the permissions tables
    #
    # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
    # @param ability [Ability] the cancan ability
    # @return [Hash] the where clause hash to pass to joins for users
    # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
    #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
    def self.user_where(access:, ability:)
      where_clause = {}
      where_clause[:agent_type] = USER
      where_clause[:agent_id] = ability.current_user.user_key
      where_clause[:access] = access
      where_clause
    end
    private_class_method :user_where

    # @api private
    #
    # Generate the group where clause hash for joining the permissions tables
    #
    # @param access [Array<String>] one or more types of access (e.g. Hyrax::PermissionTemplateAccess::MANAGE, Hyrax::PermissionTemplateAccess::DEPOSIT, Hyrax::PermissionTemplateAccess::VIEW)
    # @param ability [Ability] the cancan ability
    # @param exclude_groups [Array<String>] name of groups to exclude from the results
    # @return [Hash] the where clause hash to pass to joins for groups
    # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
    #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
    def self.group_where(access:, ability:, exclude_groups: [])
      where_clause = {}
      where_clause[:agent_type] = GROUP
      where_clause[:agent_id] = ability.user_groups - exclude_groups
      where_clause[:access] = access
      where_clause
    end
    private_class_method :group_where
  end
end
