module Hyrax
  class FileSetChangeSet < Valkyrie::ChangeSet
    property :read_users, multiple: true, required: false
    property :read_groups, multiple: true, required: false
    property :edit_users, multiple: true, required: false
    property :edit_groups, multiple: true, required: false
    property :depositor

    # delegate :depositor, :permissions, to: :model
    property :search_context, virtual: true
    # self.required_fields = [:title, :creator, :keyword, :license]
    property :title, multiple: true, required: true

    collection :permissions, virtual: true

    # TODO: Figure out where to persist these fields
    property :embargo_release_date, virtual: true
    property :lease_expiration_date, virtual: true
    property :visibility, virtual: true
    property :visibility_during_embargo, virtual: true
    property :visibility_after_embargo, virtual: true
    property :visibility_during_lease, virtual: true
    property :visibility_after_lease, virtual: true

    delegate :user, to: :search_context

    def sync
      if permissions_attributes
        self.edit_users = permission('edit', 'person') + [user.user_key]
        self.edit_groups = permission('edit', 'group')
        self.read_users = permission('read', 'person')
        self.read_groups = permission('read', 'group')
      end
      super
    end

    class_attribute :terms
    self.terms = [:resource_type, :title, :creator, :contributor, :description,
                  :keyword, :license, :publisher, :date_created, :subject, :language,
                  :identifier, :based_near, :related_url,
                  :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
                  :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
                  :visibility]

    def prepopulate!
      prepopulate_permissions
      super.tap do
        @_changes = Disposable::Twin::Changed::Changes.new
      end
    end

    def version_list
      @version_list ||= begin
        original = resource.original_file
        Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
      end
    end

    # We just need to respond to this method so that the rails nested form builder will work.
    def permissions_attributes=
      # nop
    end

    def permission(access, type)
      permissions_attributes
        .select { |attr| attr['access'] == access && attr['type'] == type }
        .map { |attr| attr['name'] }
    end

    private

      def prepopulate_permissions
        self.permissions = resource.edit_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'person') } +
                           resource.read_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'person') } +
                           resource.edit_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'group') } +
                           resource.read_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'group') }
      end
  end
end
