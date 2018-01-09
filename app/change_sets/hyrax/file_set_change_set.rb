# frozen_string_literals: true

module Hyrax
  class FileSetChangeSet < Valkyrie::ChangeSet
    property :read_users, multiple: true, required: false
    property :read_groups, multiple: true, required: false
    property :edit_users, multiple: true, required: false
    property :edit_groups, multiple: true, required: false
    property :depositor
    property :title, multiple: true, required: true

    collection :permissions, virtual: true, populator: :populate_permissions
    delegate :embargo_id, :lease_id, to: :resource
    # TODO: Figure out where to persist these fields
    property :embargo_release_date, virtual: true
    property :lease_expiration_date, virtual: true
    property :visibility, virtual: true
    property :visibility_during_embargo, virtual: true
    property :visibility_after_embargo, virtual: true
    property :visibility_during_lease, virtual: true
    property :visibility_after_lease, virtual: true

    property :user, virtual: true

    class_attribute :terms
    self.terms = [:resource_type, :title, :creator, :contributor, :description,
                  :keyword, :license, :publisher, :date_created, :subject, :language,
                  :identifier, :based_near, :related_url,
                  :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
                  :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
                  :visibility]

    # We just need to respond to this method so that the rails nested form builder will work.
    def permissions_attributes=
      # nop
    end

    # Deserializes the nested permission values from the form
    # TODO: consider a access level change
    def populate_permissions(options)
      options[:doc][:permissions_attributes].each_value do |row|
        deserialize_permission(row['agent_name'], row['type'], row['access'])
      end
      self.edit_users += [user.user_key]
    end

    def version_list
      @version_list ||= begin
        [] # TODO: remove when we have versions

        # original = resource.original_file
        # Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
      end
    end

    def page_title
      if resource.persisted?
        [resource.to_s, "#{resource.human_readable_type} [#{resource.to_param}]"]
      else
        ["New #{resource.human_readable_type}"]
      end
    end

    # Cast to a SolrDocument by querying from Solr
    def to_presenter
      document_model.find(id)
    end

    def parent
      solr = Valkyrie::MetadataAdapter.find(:index_solr).connection
      results = solr.get('select', params: { q: "{!field f=member_ids_ssim}id-#{id}",
                                             qt: 'standard' })
      ::SolrDocument.new(results['response']['docs'].first)
    end

    # Setup default values for the form.
    def prepopulate!
      self.permissions = resource.edit_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'person') } +
                         resource.read_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'person') } +
                         resource.edit_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'group') } +
                         resource.read_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'group') }
      self
    end

    private

      def deserialize_permission(agent, type, access)
        raise ArgumentError unless %w[group person].include?(type) &&
                                   %w[read edit].include?(access)

        field = if type == 'group'
                  "#{access}_groups"
                else
                  "#{access}_users"
                end
        public_send(field + '=', public_send(field) + [agent])
      end

      def document_model
        CatalogController.blacklight_config.document_model
      end
  end
end
