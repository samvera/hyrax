# frozen_string_literal: true
namespace :hyrax do
  namespace :migrate do
    desc 'Move all works to default AdminSet'
    task move_all_works_to_admin_set: :environment do
      require 'hyrax/move_all_works_to_admin_set'
      MoveAllWorksToAdminSet.run(AdminSet.find(AdminSet::DEFAULT_ID))
    end

    desc 'Add the MANAGING role to legacy works'
    task add_admin_group_to_admin_sets: :environment do
      # Force creation of registered MANAGING role if it doesn't exist
      # This code must be invoked before calling `Sipity::Role.all` or the managing role won't be there
      Sipity::Role[Hyrax::RoleRegistry::MANAGING]

      AdminSet.all.each do |admin_set|
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

    desc 'Set collection type and permissions for legacy (<2.1.0) Hyrax collections'
    task add_collection_type_and_permissions_to_collections: :environment do
      # Run collection migration which sets the collection_type of legacy collections to User Collection and adds
      # a permission template assigning users/groups with edit_access to the Manager role and users/groups with
      # read_access to the Viewer role.  Legacy collections are those created prior to collections extensions
      # added in Hyrax 2.1.0
      Hyrax::Collections::MigrationService.migrate_all_collections
    end

    # Migrate any orphan fedora data from the first to the second predicate
    desc 'Migrate keywords and license predicates for Hyrax 2.x --> 3.x'
    task migrate_keyword_and_license_predicate: :environment do
      Hyrax::Works::MigrationService.migrate_predicate(::RDF::Vocab::DC11.relation, ::RDF::Vocab::SCHEMA.keywords)
      Hyrax::Works::MigrationService.migrate_predicate(::RDF::Vocab::DC.rights, ::RDF::Vocab::DC.license)
    end
  end
end
