namespace :hyrax do
  namespace :migrate do
    task move_all_works_to_admin_set: :environment do
      require 'hyrax/move_all_works_to_admin_set'
      MoveAllWorksToAdminSet.run(Hyrax::Queries.find_by(id: AdminSet::DEFAULT_ID))
    end

    task add_admin_group_to_admin_sets: :environment do
      # Force creation of registered MANAGING role if it doesn't exist
      # This code must be invoked before calling `Sipity::Role.all` or the managing role won't be there
      Sipity::Role[Hyrax::RoleRegistry::MANAGING]

      Hyrax::Queries.find_all_of_model(model: AdminSet).each do |admin_set|
        permission_template = admin_set.permission_template
        if permission_template.access_grants.where(agent_type: 'group', agent_id: ::Ability.admin_group_name).none?
          Hyrax::PermissionTemplateAccess.create!(permission_template: permission_template,
                                                  agent_type: 'group',
                                                  agent_id: ::Ability.admin_group_name,
                                                  access: Hyrax::PermissionTemplateAccess::MANAGE)
        end
        permission_template.available_workflows.each do |workflow|
          Sipity::Role.all.each do |role|
            workflow.update_responsibilities(role: role,
                                             agents: Hyrax::Group.new(::Ability.admin_group_name))
          end
        end
      end
    end
  end
end
