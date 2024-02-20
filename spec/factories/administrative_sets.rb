# frozen_string_literal: true

FactoryBot.define do
  ##
  # This factory creates a Valkyrized adminstrative set; by default a Hyrax::AdministrativeSet
  #
  # Why the antics around the class?  Because of the Hyrax needs and potential downstream
  # applciation needs.
  #
  # Downstream applications might implement a different # administrative set and the downstream
  # application might leverage other Hyrax factories that create a `:hyrax_admin_set`
  # (e.g. `:permission_template`)
  factory :hyrax_admin_set, class: (Hyrax.config.admin_set_class < Valkyrie::Resource ? Hyrax.config.admin_set_class : Hyrax::AdministrativeSet) do
    title { ['My Admin Set'] }

    transient do
      with_permission_template { false }
      user { FactoryBot.create(:user) }
      access_grants { [] }
      with_index { true }
    end

    after(:build) do |adminset, evaluator|
      adminset.creator = [evaluator.user.user_key]
    end

    after(:create) do |admin_set, evaluator|
      admin_set.permission_manager.edit_groups = evaluator.edit_groups
      admin_set.permission_manager.edit_users  = evaluator.edit_users
      admin_set.permission_manager.read_users  = evaluator.read_users
      admin_set.permission_manager.read_groups = evaluator.read_groups

      admin_set.permission_manager.acl.save

      if evaluator.with_permission_template
        template = Hyrax::PermissionTemplate.find_or_create_by(source_id: admin_set.id.to_s)
        evaluator.access_grants.each do |grant|
          Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: template.id,
                                                            agent_type: grant[:agent_type],
                                                            agent_id: grant[:agent_id],
                                                            access: grant[:access])
        end
        Hyrax::PermissionTemplateAccess.find_or_create_by(permission_template_id: template.id,
                                                          agent_type: Hyrax::PermissionTemplateAccess::USER,
                                                          agent_id: evaluator.user.user_key,
                                                          access: Hyrax::PermissionTemplateAccess::MANAGE)
        template.reset_access_controls_for(collection: admin_set)
      end
      Hyrax.index_adapter.save(resource: admin_set) if evaluator.with_index
    end
  end

  trait :with_permission_template do
    with_permission_template { true }
    access_grants do
      [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
         agent_id: user.user_key,
         access: Hyrax::PermissionTemplateAccess::MANAGE }]
    end
  end

  factory :invalid_hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    # Title is required.  Without title, the admin set is invalid.
  end

  factory :default_hyrax_admin_set, class: 'Hyrax::AdministrativeSet' do
    id { Hyrax::AdminSetCreateService::DEFAULT_ID }
    title { Hyrax::AdminSetCreateService::DEFAULT_TITLE }

    transient do
      with_persisted_default_id { true }
    end

    after(:create) do |admin_set, evaluator|
      Hyrax::DefaultAdministrativeSet.update(default_admin_set_id: admin_set.id) if
        evaluator.with_persisted_default_id
    end
  end
end
