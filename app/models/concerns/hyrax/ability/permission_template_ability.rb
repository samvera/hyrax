# frozen_string_literal: true
module Hyrax
  module Ability
    module PermissionTemplateAbility
      def permission_template_abilities
        if admin?
          can :manage, [Hyrax::PermissionTemplate, Hyrax::PermissionTemplateAccess]
        else
          can [:create, :edit, :update, :destroy], Hyrax::PermissionTemplate do |template|
            test_edit(template.source_id)
          end
          can [:create, :edit, :update, :destroy], Hyrax::PermissionTemplateAccess do |access|
            test_edit(access.permission_template.source_id)
          end
        end
      end
    end
  end
end
