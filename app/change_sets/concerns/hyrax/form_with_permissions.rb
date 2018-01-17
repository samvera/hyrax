module Hyrax
  # Include this module on a ChangeSet that represents a form that accepts nested permissions
  module FormWithPermissions
    extend ActiveSupport::Concern

    included do
      property :read_users, multiple: true, required: false
      # read_groups could come from visibility or an individual permission
      property :read_groups, multiple: true, required: false
      property :edit_users, multiple: true, required: false
      property :edit_groups, multiple: true, required: false

      collection :permissions, virtual: true, populator: :populate_permissions
      property :user, virtual: true
    end

    # We just need to respond to this method so that the rails nested form builder will work.
    def permissions_attributes=
      # nop
    end

    # Deserializes the nested permission values from the form
    # TODO: consider a access level change
    def populate_permissions(options)
      options[:doc][:permissions_attributes].each_value do |row|
        next unless row['agent_name']
        deserialize_permission(row['agent_name'], row['type'], row['access'])
      end
    end

    # Setup default values for the form.
    def prepopulate_permissions
      self.permissions = resource.edit_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'person') } +
                         resource.read_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'person') } +
                         resource.edit_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'group') } +
                         resource.read_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'group') }
    end

    def permissions_changed?
      changed.include?('edit_users') ||
        changed.include?('edit_groups') ||
        changed.include?('read_users') ||
        changed.include?('read_groups')
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
  end
end
