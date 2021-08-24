# frozen_string_literal: true
module Hyrax
  # Responsible for creating an Hyrax::AdministrativeSet and its corresponding data:
  #
  # * An associated permission template
  # * Available workflows
  # * An active workflow
  #
  # @see Hyrax::AdministrativeSet
  # @see Hyrax::PermissionTemplate
  # @see Sipity::Workflow
  class AdminSetCreateService # rubocop:disable Metrics/ClassLength
    DEFAULT_ID = 'admin_set/default'
    DEFAULT_TITLE = ['Default Admin Set'].freeze

    class << self
      # @api public
      # Creates the default Hyrax::AdministrativeSet and corresponding data
      # @return [Hyrax::AdministrativeSet] The default admin set.
      # @see Hyrax::AdministrativeSet
      # @raise [RuntimeError] if admin set cannot be persisted
      def find_or_create_default_admin_set
        Hyrax.query_service.find_by(id: DEFAULT_ID)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        create_default_admin_set!
      end

      # @api public
      # Creates the default Hyrax::AdministrativeSet and corresponding data
      # @param admin_set_id [String] The default admin set ID
      # @param title [Array<String>] The title of the default admin set
      # @return [TrueClass]
      # @deprecated
      # @see Hyrax::AdministrativeSet
      # TODO: When this deprecated method is removed, update private method
      #       .create_default_admin_set! to remove the parameters.
      def create_default_admin_set(admin_set_id: DEFAULT_ID, title: DEFAULT_TITLE)
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                           "Instead, use Hyrax::AdminSetCreateService.find_or_create_default_admin_set.")
        admin_set = create_default_admin_set!(admin_set_id: admin_set_id, title: title)
        admin_set.present?
      rescue RuntimeError => _err
        false
      end

      # @api public
      # Is the admin_set the default Hyrax::AdministrativeSet
      # @param admin_set [Hyrax::AdministrativeSet] the admin set to operate on
      def default_admin_set?(id:)
        id == DEFAULT_ID
      end

      # @api public
      # Creates a non-default Hyrax::AdministrativeSet and corresponding data
      # @param admin_set [Hyrax::AdministrativeSet] the admin set to operate on
      # @param creating_user [User] the user who created the admin set
      # @return [TrueClass, FalseClass] true if it was successful
      # @see Hyrax::AdministrativeSet
      # @raise [RuntimeError] if you attempt to create a default admin set via this mechanism
      def call(admin_set:, creating_user:, **kwargs)
        admin_set = call!(admin_set: admin_set, creating_user: creating_user, **kwargs)
        admin_set.present?
      rescue RuntimeError => _err
        false
      end

      # @api public
      # Creates a non-default Hyrax::AdministrativeSet and corresponding data
      # @param admin_set [Hyrax::AdministrativeSet] the admin set to operate on
      # @param creating_user [User] the user who created the admin set
      # @return [Hyrax::AdministrativeSet] The fully created admin set.
      # @see Hyrax::AdministrativeSet
      # @raise [RuntimeError] if you attempt to create a default admin set via this mechanism
      # @raise [RuntimeError] if admin set cannot be persisted
      def call!(admin_set:, creating_user:, **kwargs)
        raise "Use .create_default_admin_set to create a default admin set" if default_admin_set?(id: admin_set.id)
        new(admin_set: admin_set, creating_user: creating_user, **kwargs).create!
      end

      private

      # Creates the default Hyrax::AdministrativeSet and corresponding data
      # @param admin_set_id [String] The default admin set ID
      # @param title [Array<String>] The title of the default admin set
      # @return [Hyrax::AdministrativeSet] The default admin set.
      # @see Hyrax::AdministrativeSet
      # @raise [RuntimeError] if admin set cannot be persisted
      # TODO: Parameters admin_set_id and title are defined to support .create_default_admin_set.
      #       This is a deprecated method.  When it is removed, the parameters will no
      #       longer be required.
      def create_default_admin_set!(admin_set_id: DEFAULT_ID, title: DEFAULT_TITLE)
        admin_set = Hyrax::AdministrativeSet.new(id: admin_set_id, title: Array.wrap(title))
        new(admin_set: admin_set, creating_user: ::User.system_user).create!
      end
    end

    # @param admin_set [Hyrax::AdministrativeSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set (if any).
    # @param workflow_importer [#call] imports the workflow
    def initialize(admin_set:, creating_user:, workflow_importer: default_workflow_importer)
      validate_admin_set(admin_set)
      @admin_set = admin_set
      @creating_user = creating_user
      @workflow_importer = workflow_importer
    end

    attr_reader :creating_user, :admin_set, :workflow_importer

    # Creates an admin set, setting the creator and the default access controls.
    # @return [TrueClass, FalseClass] true if it was successful
    def create
      create!
      true
    rescue RuntimeError => _err
      false
    end

    # Creates an admin set, setting the creator and the default access controls.
    # @return [Hyrax::AdministrativeSet] The fully created admin set.
    # @raise [RuntimeError] if admin set cannot be persisted
    def create!
      admin_set.creator = [creating_user.user_key] if creating_user
      updated_admin_set = Hyrax.persister.save(resource: admin_set).tap do |result|
        if result
          ActiveRecord::Base.transaction do
            permission_template = create_permission_template
            workflow = create_workflows_for(permission_template: permission_template)
            create_default_access_for(permission_template: permission_template, workflow: workflow) if default_admin_set?(admin_set.id)
          end
        end
      end
      Hyrax.publisher.publish('object.metadata.updated', object: updated_admin_set, user: creating_user)
      updated_admin_set
    end

    private

    def access_grants_attributes(permission_template:)
      Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: permission_template.id,
                                                        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
                                                        agent_id: ::Ability.admin_group_name,
                                                        access: Hyrax::PermissionTemplateAccess::MANAGE)
      if creating_user.present? # rubocop:disable Style/GuardClause
        Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: permission_template.id,
                                                          agent_type: Hyrax::PermissionTemplateAccess::USER,
                                                          agent_id: creating_user.user_key,
                                                          access: Hyrax::PermissionTemplateAccess::MANAGE)
      end
    end

    def admin_group_name
      ::Ability.admin_group_name
    end

    # @return [PermissionTemplate]
    def create_permission_template
      permission_template = Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set.id.to_s)
      access_grants_attributes(permission_template: permission_template)
      permission_template
    end

    def create_workflows_for(permission_template:)
      workflow_importer.call(permission_template: permission_template)
      grant_all_workflow_roles_to_creating_user_and_admins!(permission_template: permission_template)
      Sipity::Workflow.activate!(permission_template: permission_template, workflow_name: Hyrax.config.default_active_workflow_name)
    end

    # Force creation of registered MANAGING role if it doesn't exist
    def register_managing_role!
      Sipity::Role[Hyrax::RoleRegistry::MANAGING]
    end

    def grant_all_workflow_roles_to_creating_user_and_admins!(permission_template:)
      # This code must be invoked before calling `Sipity::Role.all` or the managing role won't be there
      register_managing_role!
      # Grant all workflow roles to the creating_user and the admin group
      permission_template.available_workflows.each do |workflow|
        Sipity::Role.all.each do |role|
          workflow.update_responsibilities(role: role,
                                           agents: workflow_agents)
        end
      end
    end

    def workflow_agents
      [
        Hyrax::Group.new(admin_group_name)
      ].tap do |agent_list|
        # The default admin set does not have a creating user
        agent_list << creating_user if creating_user
      end
    end

    # Gives deposit access to registered users to default AdminSet
    def create_default_access_for(permission_template:, workflow:)
      Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: permission_template.id,
                                                        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
                                                        agent_id: ::Ability.registered_group_name,
                                                        access: Hyrax::PermissionTemplateAccess::DEPOSIT)
      deposit = Sipity::Role[Hyrax::RoleRegistry::DEPOSITING]
      workflow.update_responsibilities(role: deposit, agents: Hyrax::Group.new('registered'))
    end

    def default_workflow_importer
      Hyrax::Workflow::WorkflowImporter.method(:load_workflow_for)
    end

    def validate_admin_set(admin_set)
      raise(ArgumentError, "admin_set is expected to be a Hyrax::AdministrativeSet") unless
        admin_set.is_a? Hyrax::AdministrativeSet
    end

    def default_admin_set?(id)
      self.class.default_admin_set?(id: id)
    end
  end
end
