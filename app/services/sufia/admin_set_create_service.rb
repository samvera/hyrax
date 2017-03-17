module Sufia
  # Creates AdminSets
  class AdminSetCreateService
    DEFAULT_WORKFLOW_NAME = 'default'.freeze

    def self.create_default!
      return if AdminSet.exists?(AdminSet::DEFAULT_ID)
      admin_set = AdminSet.new(id: AdminSet::DEFAULT_ID, title: ['Default Admin Set'])
      begin
        new(admin_set, nil, DEFAULT_WORKFLOW_NAME).create
      rescue ActiveFedora::IllegalOperation
        # It is possible that another thread created the AdminSet just before this method
        # was called, so ActiveFedora will raise IllegalOperation. In this case we can safely
        # ignore the error.
        Rails.logger.error("AdminSet ID=#{AdminSet::DEFAULT_ID} may or may not have been created due to threading issues.")
      end
    end

    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set.
    def initialize(admin_set, creating_user, workflow_name)
      @admin_set = admin_set
      @creating_user = creating_user
      @workflow_name = workflow_name
    end

    attr_reader :creating_user, :admin_set, :workflow_name

    # Creates an admin set, setting the creator and the default access controls.
    # @return [TrueClass, FalseClass] true if it was successful
    def create
      admin_set.read_groups = ['public']
      admin_set.edit_groups = ['admin']
      admin_set.creator = [creating_user.user_key] if creating_user
      admin_set.save.tap do |result|
        create_permission_template if result
      end
    end

    def access_grants_attributes
      return [] unless creating_user
      [{ agent_type: 'user', agent_id: creating_user.user_key, access: 'manage' }]
    end

    def create_permission_template
      PermissionTemplate.create!(admin_set_id: admin_set.id,
                                 access_grants_attributes: access_grants_attributes,
                                 workflow_name: workflow_name)
    end
  end
end
