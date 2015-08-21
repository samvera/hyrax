module CurationConcerns
  module Permissions
    module Writable
      extend ActiveSupport::Concern

      # we're overriding the permissions= method which is in Hydra::AccessControls::Permissions
      include Hydra::AccessControls::Permissions
      include Hydra::AccessControls::Visibility

      included do
        validate :paranoid_permissions
      end

      def paranoid_permissions
        valid = true
        paranoid_edit_permissions.each do |validation|
          next unless validation[:condition].call(self)
          errors[validation[:key]] ||= []
          errors[validation[:key]] << validation[:message]
          valid = false
        end
        valid
      end

      def paranoid_edit_permissions
        [
          { key: :edit_users, message: 'Depositor must have edit access', condition: ->(obj) { !obj.edit_users.include?(obj.depositor) } },
          { key: :edit_groups, message: 'Public cannot have edit access', condition: ->(obj) { obj.edit_groups.include?('public') } },
          { key: :edit_groups, message: 'Registered cannot have edit access', condition: ->(obj) { obj.edit_groups.include?('registered') } }
        ]
      end

      def clear_permissions!
        self.permissions = []
      end

      ## Updates those permissions that are provided to it. Does not replace any permissions unless they are provided
      # def permissions=(params)
      #   raise "Fixme #{params}"
      #   perm_hash = permission_hash
      #   params[:new_user_name].each { |name, access| perm_hash['person'][name] = access } if params[:new_user_name].present?
      #   params[:new_group_name].each { |name, access| perm_hash['group'][name] = access } if params[:new_group_name].present?

      #   params[:user].each { |name, access| perm_hash['person'][name] = access} if params[:user]
      #   params[:group].each { |name, access| perm_hash['group'][name] = access if ['read', 'edit'].include?(access)} if params[:group]

      #   # rightsMetadata.update_permissions(perm_hash)
      # end

      # def permissions
      #   raise "Fixme "
      #   perms = super
      #   perms.map {|p| { name: p.name, access: p.access, type:p.type } }
      # end

      private

        def permission_hash
          old_perms = permissions
          user_perms = {}
          old_perms.select { |r| r[:type] == 'user' }.each do |r|
            user_perms[r[:name]] = r[:access]
          end
          group_perms = {}
          old_perms.select { |r| r[:type] == 'group' }.each do |r|
            group_perms[r[:name]] = r[:access]
          end
          { 'person' => user_perms, 'group' => group_perms }
        end
    end
  end
end
