module Hyrax
  # Creates AdminSets
  class AdminSetCreateService
    # Creates an admin set, setting the creator and the default access controls.
    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set.
    # @return [TrueClass, FalseClass] true if it was successful
    def self.call(admin_set, creating_user, **kwargs)
      new(admin_set, creating_user, **kwargs).create
    end

    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set.
    def initialize(admin_set, creating_user, workflow_importer: default_workflow_importer)
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
      admin_set.creator = [creating_user.user_key]
      admin_set.save.tap do |result|
        if result
          permission_template = create_permission_template
          create_workflows_for(permission_template: permission_template)
        end
      end
    end

    private

      def create_permission_template
        PermissionTemplate.create!(admin_set_id: admin_set.id,
                                   access_grants_attributes: [{ agent_type: 'user',
                                                                agent_id: creating_user.user_key,
                                                                access: 'manage' }])
      end

      def create_workflows_for(permission_template:)
        workflow_importer.call(permission_template: permission_template)
      end

      def default_workflow_importer
        Hyrax::Workflow::WorkflowImporter.method(:load_workflow_for)
      end
  end
end
