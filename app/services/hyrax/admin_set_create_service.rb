# frozen_string_literal: true
module Hyrax
  # Responsible for creating a Hyrax::AdministrativeSet and its corresponding data.
  #
  # * An associated permission template
  # * Available workflows
  # * An active workflow
  #
  # @see Hyrax::AdministrativeSet
  # @see Hyrax::PermissionTemplate
  # @see Sipity::Workflow
  class AdminSetCreateService # rubocop:disable Metrics/ClassLength
    DEFAULT_ID = 'admin_set_default'
    DEFAULT_TITLE = ['Default Admin Set'].freeze

    class_attribute :permissions_create_service, :default_admin_set_persister
    self.permissions_create_service = Hyrax::Collections::PermissionsCreateService
    self.default_admin_set_persister = Hyrax::DefaultAdministrativeSet

    class << self
      # @api public
      # Finds the default AdministrativeSet if it exists; otherwise, creates it and corresponding data
      # @return [Hyrax::AdministrativeSet] The default admin set.
      # @see Hyrax::AdministrativeSet
      # @raise [RuntimeError] if admin set cannot be persisted
      def find_or_create_default_admin_set
        find_default_admin_set || create_default_admin_set!
      end

      # @api public
      # @param id [#to_s] id of the admin set to check
      # @return [Boolean] true if the id is for the default admin set; otherwise, false
      def default_admin_set?(id:)
        return false if id.blank?
        id.to_s == default_admin_set_id
      end

      # @api public
      # Creates a non-default Hyrax::AdministrativeSet and corresponding data
      # @param admin_set [Hyrax::AdministrativeSet | AdminSet] the admin set to operate on
      # @param creating_user [User] the user who created the admin set
      # @return [TrueClass, FalseClass] true if it was successful
      # @see Hyrax::AdministrativeSet
      # @raise [RuntimeError] if you attempt to create a default admin set via this mechanism
      # @deprecated
      def call(admin_set:, creating_user:, **kwargs)
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Warning: This method may hide runtime errors.  " \
                         "Instead, use 'Hyrax::AdminSetCreateService.call!'.  ")
        call!(admin_set: admin_set_resource(admin_set), creating_user: creating_user, **kwargs).present?
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

      # TODO: Parameters admin_set_id and title are defined to support .create_default_admin_set
      #       which is deprecated.  When it is removed, the parameters will no longer be required.
      def create_default_admin_set!(admin_set_id: DEFAULT_ID, title: DEFAULT_TITLE)
        admin_set = create_admin_set(suggested_id: admin_set_id, title: title)
        admin_set = new(admin_set: admin_set, creating_user: nil, default_admin_set: true).create!
        default_admin_set_persister.update(default_admin_set_id: admin_set.id) if save_default?
        admin_set
      end

      def save_default?
        default_admin_set_persister.save_supported?
      end

      # Create an instance of `Hyrax::AdministrativeSet` with the suggested_id if supported.
      # @return [Hyrax::AdministrativeSet] the new admin set
      def create_admin_set(suggested_id:, title:)
        # Leverage the configured admin class, if it is a Valkyrie resource, otherwise fallback.
        # Until we have fully moved to Valkyrie, we will need this logic.  Once past, we can
        # use `Hyrax.config.admin_set_class`
        klass = Hyrax.config.admin_set_class < Valkyrie::Resource ? Hyrax.config.admin_set_class : Hyrax::AdministrativeSet
        if suggested_id.blank? || Hyrax.config.disable_wings
          # allow persister to assign id
          klass.new(title: Array.wrap(title))
        else
          # use suggested_id
          klass.new(id: suggested_id, title: Array.wrap(title))
        end
      end

      # Find default AdministrativeSet using saved id
      # @return [Hyrax::AdministrativeSet] the default admin set; nil if id not saved
      # @raise [RuntimeError] if an admin set with the saved id doesn't exist
      def find_default_admin_set
        id = default_admin_set_id
        return if id.blank?
        Hyrax.query_service.find_by(id: id)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        # The default ID is DEFAULT_ID when saving is not supported.  It is ok
        # for this default id to be known but not found.  The admin set will be
        # created with DEFAULT_ID by find_or_create_default_admin_set.
        return unless save_default?

        # id is saved in the default_admin_set_persister's table but doesn't exist
        # NOTE: This is a corrupt state and shouldn't happen.  Manual intervention
        #       is required to determine the correct value for the default admin
        #       set id.  The saved id either needs to be updated to the correct
        #       value or deleted to allow a new default admin set to be found
        #       (i.e. an admin set with id DEFAULT_ID) or generated.
        raise "Corrupt default admin set.  Persisted admin set with saved default_admin_set_id doesn't exist."
      end

      # Find default AdministrativeSet using DEFAULT_ID.
      # @note Use of hardcoded ID is being deprecated as some Valkyrie adapters
      #       do not support hardcoded IDs (e.g. postgres)
      # @return [Hyrax::AdministrativeSet] the default admin set; nil if not found
      def find_unsaved_default_admin_set
        admin_set = begin
                      # to support repositories still using the deprecated 'admin_set/default' as DEFAULT_ID
                      Hyrax.query_service.find_by(id: 'admin_set/default')
                    rescue Ldp::BadRequest, Valkyrie::Persistence::ObjectNotFoundError
                      # Fedora 6.5+ does not support slashes in IDs, hence the need to rescue Ldp::BadRequest
                      # if an admin set with deprecated ID 'admin_set/default' does not exist, check again for admin set with DEFAULT_ID
                      begin
                        Hyrax.query_service.find_by(id: DEFAULT_ID)
                      rescue Valkyrie::Persistence::ObjectNotFoundError
                        nil
                      end
                    end

        default_admin_set_persister.update(default_admin_set_id: admin_set.id.to_s) if admin_set.present? && save_default?

        admin_set
      end

      # @return [String | nil] the default admin set id; returns nil if not set
      # @note For general use, it is better to use `Hyrax.config.default_admin_set_id`.
      def default_admin_set_id
        return DEFAULT_ID unless save_default?
        id = default_admin_set_persister.first&.default_admin_set_id
        id = find_unsaved_default_admin_set&.id&.to_s if id.blank?
        id
      end

      def admin_set_resource(admin_set)
        case admin_set
        when Valkyrie::Resource
          admin_set
        else
          admin_set.valkyrie_resource
        end
      end
    end

    # @param admin_set [Hyrax::AdministrativeSet | AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set (if any).
    # @param workflow_importer [#call] imports the workflow
    def initialize(admin_set:, creating_user:, workflow_importer: default_workflow_importer, default_admin_set: false)
      @admin_set = Hyrax::AdminSetCreateService.send(:admin_set_resource, admin_set)
      @creating_user = creating_user
      @workflow_importer = workflow_importer
      @default_admin_set = default_admin_set
    end

    attr_reader :creating_user, :admin_set, :workflow_importer

    # Creates an admin set, setting the creator and the default access controls.
    # @return [TrueClass, FalseClass] true if it was successful
    # @deprecated
    def create
      Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Warning: This method may hide runtime errors.  " \
                         "Instead, use 'Hyrax::AdminSetCreateService.create!'.  ")
      create!.persisted?
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
            permission_template = PermissionTemplate.find_by(source_id: result.id.to_s) ||
                                  permissions_create_service.create_default(collection: result,
                                                                            creating_user: creating_user)
            workflow = create_workflows_for(permission_template: permission_template)
            create_default_access_for(permission_template: permission_template, workflow: workflow) if default_admin_set?
          end
        end
      end
      Hyrax.publisher.publish('collection.metadata.updated', collection: updated_admin_set, user: creating_user)
      updated_admin_set
    end

    private

    def default_admin_set?
      @default_admin_set
    end

    def admin_group_name
      ::Ability.admin_group_name
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
        Sipity::Agent(Hyrax::Group.new(admin_group_name))
      ].tap do |agent_list|
        # The default admin set does not have a creating user
        agent_list << Sipity::Agent(creating_user) if creating_user
      end
    end

    # Give registered users deposit access to default admin set
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
