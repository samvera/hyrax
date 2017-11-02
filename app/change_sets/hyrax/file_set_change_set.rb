module Hyrax
  class FileSetChangeSet < Valkyrie::ChangeSet
    property :read_users, multiple: true, required: false
    property :read_groups, multiple: true, required: false
    property :edit_users, multiple: true, required: false
    property :edit_groups, multiple: true, required: false

    # delegate :depositor, :permissions, to: :model
    property :search_context, virtual: true
    # self.required_fields = [:title, :creator, :keyword, :license]
    property :title, multiple: true, required: true

    collection :permissions_attributes, virtual: true

    def user
      search_context.current_ability.current_user
    end

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

    def version_list
      @version_list ||= begin
        original = resource.original_file
        Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
      end
    end

    def permission(access, type)
      permissions_attributes
        .select { |attr| attr['access'] == access && attr['type'] == type }
        .map { |attr| attr['name'] }
    end
  end
end
