# frozen_string_literal: true
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
  class AdminSetCreateService # rubocop:disable Metrics/ClassLength
    DEFAULT_ID = 'admin_set/default'
    DEFAULT_TITLE = ['Default Admin Set'].freeze

    class_attribute :permissions_create_service
    self.permissions_create_service = Hyrax::Collections::PermissionsCreateService

    class << self
      # @api public
      # Creates the default AdminSet and corresponding data
      # @param admin_set_id [String] The default admin set ID
      # @param title [Array<String>] The title of the default admin set
      # @return [TrueClass]
      # @see AdminSet
      # @deprecated
      # TODO: When this deprecated method is removed, update private method
      #       .create_default_admin_set! to remove the parameters.
      def create_default_admin_set(admin_set_id: DEFAULT_ID, title: DEFAULT_TITLE)
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use 'Hyrax::AdminSetCreateService.find_or_create_default_admin_set'.")
        create_default_admin_set!(admin_set_id: admin_set_id, title: title).present?
      rescue RuntimeError => _err
        false
      end

      # @api public
      # Finds the default AdminSet if it exists; otherwise, creates it and corresponding data
      # @return [Hyrax::AdministrativeSet] The default admin set.
      # @see Hyrax::AdministrativeSet
      # @raise [RuntimeError] if admin set cannot be persisted
      def find_or_create_default_admin_set
        Hyrax.query_service.find_by(id: DEFAULT_ID)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        create_default_admin_set!
      end

      # @api public
      # Is the admin_set the default Hyrax::AdministrativeSet
      # @param id [#to_s] the id of the admin set to check
      def default_admin_set?(id:)
        id.to_s == DEFAULT_ID
      end

      # @api public
      # Creates a non-default AdminSet and corresponding data
      # @param admin_set [AdminSet] the admin set to operate on
      # @param creating_user [User] the user who created the admin set
      # @return [TrueClass, FalseClass] true if it was successful
      # @see AdminSet
      # @raise [RuntimeError] if you attempt to create a default admin set via this mechanism
      def call(admin_set:, creating_user:, **kwargs)
        call!(admin_set: admin_set, creating_user: creating_user, **kwargs).present?
      rescue RuntimeError => err
        raise err if default_admin_set?(id: admin_set.id)
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
        raise "Use .find_or_create_default_admin_set to create a default admin set" if default_admin_set?(id: admin_set.id)
        new(admin_set: admin_set, creating_user: creating_user, **kwargs).create!
      end

      private

      def create_default_admin_set!(admin_set_id: DEFAULT_ID, title: DEFAULT_TITLE)
        admin_set = AdminSet.new(id: admin_set_id, title: Array.wrap(title))
        begin
          new(admin_set: admin_set, creating_user: nil).create!
        rescue ActiveFedora::IllegalOperation
          # It is possible that another thread created the AdminSet just before this method
          # was called, so ActiveFedora will raise IllegalOperation. In this case we can safely
          # ignore the error.
          Rails.logger.error("AdminSet ID=#{AdminSet::DEFAULT_ID} may or may not have been created due to threading issues.")
        end
        Hyrax.query_service.find_by(id: DEFAULT_ID)
      end
    end

    # @param admin_set [Hyrax::AdministrativeSet | AdminSet] the admin set to operate on
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
      create!.persisted?
    rescue RuntimeError => _err
      false
    end

    # Creates an admin set, setting the creator and the default access controls.
    # @return [Hyrax::AdministrativeSet] The fully created admin set.
    # @raise [RuntimeError] if admin set cannot be persisted
    def create!
      admin_set.respond_to?(:valkyrie_resource) ? active_fedora_create! : valkyrie_create!
    end

    private

    def default_admin_set?(id:)
      self.class.default_admin_set?(id: id)
    end

    def admin_group_name
      ::Ability.admin_group_name
    end

    # Creates an admin set, setting the creator and the default access controls.
    # @return [Hyrax::AdministrativeSet] The fully created admin set.
    # @raise [RuntimeError] if admin set cannot be persisted
    def valkyrie_create!
      admin_set.creator = [creating_user.user_key] if creating_user
      updated_admin_set = Hyrax.persister.save(resource: admin_set).tap do |result|
        if result
          ActiveRecord::Base.transaction do
            permission_template = permissions_create_service.create_default(collection: admin_set,
                                                                            creating_user: creating_user)
            workflow = create_workflows_for(permission_template: permission_template)
            create_default_access_for(permission_template: permission_template, workflow: workflow) if default_admin_set?(id: admin_set.id)
          end
        end
      end
      Hyrax.publisher.publish('collection.metadata.updated', collection: updated_admin_set, user: creating_user)
      updated_admin_set
    end

    # Creates an admin set, setting the creator and the default access controls.
    # @return [Hyrax::AdministrativeSet] The fully created admin set.
    # @raise [RuntimeError] if admin set cannot be persisted
    def active_fedora_create!
      admin_set.creator = [creating_user.user_key] if creating_user
      admin_set.save.tap do |result|
        if result
          ActiveRecord::Base.transaction do
            permission_template = permissions_create_service.create_default(collection: admin_set,
                                                                            creating_user: creating_user)
            workflow = create_workflows_for(permission_template: permission_template)
            create_default_access_for(permission_template: permission_template, workflow: workflow) if default_admin_set?(id: admin_set.id)
          end
        end
      end
      raise 'Admin set failed to persist.' unless admin_set.persisted?
      admin_set.valkyrie_resource
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
      permission_template.access_grants.create(agent_type: 'group', agent_id: ::Ability.registered_group_name, access: Hyrax::PermissionTemplateAccess::DEPOSIT)
      deposit = Sipity::Role[Hyrax::RoleRegistry::DEPOSITING]
      workflow.update_responsibilities(role: deposit, agents: Hyrax::Group.new('registered'))
    end

    def default_workflow_importer
      Hyrax::Workflow::WorkflowImporter.method(:load_workflow_for)
    end
  end
end
