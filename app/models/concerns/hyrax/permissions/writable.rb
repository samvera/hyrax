module Hyrax
  module Permissions
    module Writable
      extend ActiveSupport::Concern

      # we're overriding the permissions= method which is in Hydra::AccessControls::Permissions
      # include Hydra::AccessControls::Permissions
      include Hydra::AccessControls::Visibility

      included do
        include Valkyrie::Resource::AccessControls

        # validate :paranoid_permissions

        # class_attribute :paranoid_edit_permissions
        # self.paranoid_edit_permissions =
        #   [
        #     { key: :edit_groups, message: 'Public cannot have edit access', condition: ->(obj) { obj.edit_groups.include?('public') } },
        #     { key: :edit_groups, message: 'Registered cannot have edit access', condition: ->(obj) { obj.edit_groups.include?('registered') } }
        #   ]
      end

      # def paranoid_permissions
      #   valid = true
      #   paranoid_edit_permissions.each do |validation|
      #     next unless validation[:condition].call(self)
      #     errors[validation[:key]] ||= []
      #     errors[validation[:key]] << validation[:message]
      #     valid = false
      #   end
      #   valid
      # end
    end
  end
end
