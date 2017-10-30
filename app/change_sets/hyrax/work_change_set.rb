module Hyrax
  class WorkChangeSet < Valkyrie::ChangeSet
    class_attribute :workflow_class, :exclude_fields, :primary_terms, :secondary_terms
    delegate :human_readable_type, to: :resource

    # Which fields show above the fold.
    self.primary_terms = [:title, :creator, :keyword, :rights_statement]
    self.secondary_terms = [:contributor, :description, :license, :publisher,
                            :date_created, :subject, :language, :identifier,
                            :based_near, :related_url, :source]

    # Don't create accessors for these fields
    self.exclude_fields = [:internal_resource, :id, :read_groups, :read_users, :edit_users, :edit_groups]

    # Used for searching
    property :search_context, virtual: true, multiple: false, required: false

    # TODO: Figure out where to persist these fields
    property :embargo_release_date, virtual: true
    property :lease_expiration_date, virtual: true
    property :visibility, virtual: true
    property :visibility_during_embargo, virtual: true
    property :visibility_after_embargo, virtual: true
    property :visibility_during_lease, virtual: true
    property :visibility_after_lease, virtual: true

    # TODO: this should be validated
    property :agreement_accepted, virtual: true

    # TODO: how do we get an etag?
    property :version, virtual: true

    collection :permissions, virtual: true

    class << self
      def work_klass
        name.sub(/ChangeSet$/, '').constantize
      end

      def autocreate_fields!
        self.fields = work_klass.schema.keys + [:resource_type] - [:internal_resource, :id, :read_groups, :read_users, :edit_users, :edit_groups]
      end
    end

    def self.apply_workflow(workflow)
      self.workflow_class = workflow
      include(Valhalla::ChangeSetWorkflow)
    end

    def prepopulate!
      prepopulate_permissions
      super.tap do
        @_changes = Disposable::Twin::Changed::Changes.new
      end
    end

    # We just need to respond to this method so that the rails nested form builder will work.
    def permissions_attributes=
      # nop
    end

    def prepopulate_permissions
      self.permissions = resource.edit_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'person') } +
                         resource.read_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'person') } +
                         resource.edit_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'group') } +
                         resource.read_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'group') }
    end

    def page_title
      if resource.persisted?
        [resource.to_s, "#{resource.human_readable_type} [#{resource.to_param}]"]
      else
        ["New #{resource.human_readable_type}"]
      end
    end

    # Do not display additional fields if there are no secondary terms
    # @return [Boolean] display additional fields on the form?
    def display_additional_fields?
      secondary_terms.any?
    end

    # Get a list of collection id/title pairs for the select form
    def collections_for_select
      collection_service = CollectionsService.new(search_context)
      CollectionOptionsPresenter.new(collection_service).select_options(:edit)
    end

    # Select collection(s) based on passed-in params and existing memberships.
    # @return [Array] a list of collection identifiers
    def member_of_collections(collection_ids)
      (member_of_collection_ids + Array.wrap(collection_ids)).uniq
    end

    # admin_set_id is required on the client, otherwise simple_form renders a blank option.
    # however it isn't a required field for someone to submit via json.
    # Set the first admin_set they have access to.
    def admin_set_id
      admin_set = Hyrax::AdminSetService.new(search_context).search_results(:deposit).first
      admin_set && admin_set.id
    end
  end
end
