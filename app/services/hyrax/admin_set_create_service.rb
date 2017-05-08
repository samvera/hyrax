module Hyrax
  # Responsible for creating an AdminSet and its corresponding data:
  #
  # * An associated permission template
  # * Available workflows
  # * An active workflow
  #
  # @see AdminSet
  # @see Hyrax::PermissionTemplate
  # @see Sipity::Workflow
  class AdminSetCreateService
    # @api public
    # Creates the default AdminSet and corresponding data
    # @param admin_set_id [String] The default admin set ID
    # @param title [Array<String>] The title of the default admin set
    # @return [TrueClass]
    # @see AdminSet
    def self.create_default_admin_set(admin_set_id:, title:)
      admin_set = AdminSet.new(id: admin_set_id, title: Array.wrap(title))
      begin
        new(admin_set: admin_set, creating_user: nil).create
      rescue ActiveFedora::IllegalOperation
        # It is possible that another thread created the AdminSet just before this method
        # was called, so ActiveFedora will raise IllegalOperation. In this case we can safely
        # ignore the error.
        Rails.logger.error("AdminSet ID=#{AdminSet::DEFAULT_ID} may or may not have been created due to threading issues.")
      end
    end

    # @api public
    # Creates a non-default AdminSet and corresponding data
    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set
    # @return [TrueClass, FalseClass] true if it was successful
    # @see AdminSet
    # @raise [RuntimeError] if you attempt to create a default admin set via this mechanism
    def self.call(admin_set:, creating_user:, **kwargs)
      raise "Use .create_default_admin_set to create a default admin set" if admin_set.default_set?
      new(admin_set: admin_set, creating_user: creating_user, **kwargs).create
    end

    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set (if any).
    # @param workflow_importer [#call] imports the workflow
    def initialize(admin_set:, creating_user:, workflow_importer: default_workflow_importer)
      @admin_set = admin_set
      @creating_user = creating_user
      @workflow_importer = workflow_importer
    end

    attr_reader :creating_user, :admin_set, :workflow_importer

    # Creates an admin set, setting the creator and the default access controls.
    # @return [TrueClass, FalseClass] true if it was successful
    def create
      admin_set.read_groups = ['public']
      admin_set.edit_groups = ['admin']
      admin_set.creator = [creating_user.user_key] if creating_user
      admin_set.save.tap do |result|
        if result
          ActiveRecord::Base.transaction do
            permission_template = create_permission_template
            workflow = create_workflows_for(permission_template: permission_template)
            create_default_access_for(permission_template: permission_template, workflow: workflow) if admin_set.default_set?
          end
        end
      end
    end

    private

      def access_grants_attributes
        return [] unless creating_user
        [{ agent_type: 'user', agent_id: creating_user.user_key, access: 'manage' }]
      end

      def create_permission_template
        PermissionTemplate.create!(admin_set_id: admin_set.id, access_grants_attributes: access_grants_attributes)
      end

      def create_workflows_for(permission_template:)
        workflow_importer.call(permission_template: permission_template)
        grant_all_workflow_roles_to_creating_user!(permission_template: permission_template)
        Sipity::Workflow.activate!(permission_template: permission_template, workflow_name: Hyrax.config.default_active_workflow_name)
      end

      def grant_all_workflow_roles_to_creating_user!(permission_template:)
        # Default admin set has a nil creating_user; guard against that condition
        return if creating_user.nil?
        # Grant all workflow roles to the creating_user
        permission_template.available_workflows.each do |workflow|
          Sipity::Role.all.each do |role|
            workflow.update_responsibilities(role: role, agents: creating_user.to_sipity_agent)
          end
        end
      end

      # Gives deposit access to all registered users
      def create_default_access_for(permission_template:, workflow:)
        permission_template.access_grants.create(agent_type: 'group', agent_id: 'registered', access: 'deposit')
        deposit = Sipity::Role.find_by_name!('depositing')
        workflow.update_responsibilities(role: deposit, agents: Hyrax::Group.new('registered'))
      end

      def default_workflow_importer
        Hyrax::Workflow::WorkflowImporter.method(:load_workflow_for)
      end
  end
end
