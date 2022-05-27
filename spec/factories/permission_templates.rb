# frozen_string_literal: true
FactoryBot.define do
  factory :permission_template, class: Hyrax::PermissionTemplate do
    # Given that there is a one to one strong relation between permission_template and admin_set,
    # with a unique index on the source_id, I don't want to have duplication in source_id
    sequence(:source_id) { |n| format("%010d", n) }

    trait :with_immediate_release do
      release_period { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY }
    end

    trait :with_delayed_release do
      release_period { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_6_MONTHS }
    end

    before(:create) do |permission_template, evaluator|
      if evaluator.with_admin_set
        source_id = permission_template.source_id
        admin_set = SourceFinder.find_or_create_admin_set(source_id)
        permission_template.source_id = admin_set.id
      elsif evaluator.with_collection
        source_id = permission_template.source_id
        collection =
          if source_id.present?
            begin
              Collection.find(source_id)
            rescue ActiveFedora::ObjectNotFoundError
              create(:collection, id: source_id)
            end
          else
            create(:collection)
          end
        permission_template.source_id = collection.id
      end
    end

    after(:create) do |permission_template, evaluator|
      if evaluator.with_workflows
        Hyrax::Workflow::WorkflowImporter.load_workflow_for(permission_template: permission_template)
        Sipity::Workflow.activate!(permission_template: permission_template, workflow_id: permission_template.available_workflows.pick(:id))
      end
      if evaluator.with_active_workflow
        workflow = create(:workflow, active: true, permission_template: permission_template)
        create(:workflow_action, workflow: workflow) # Need to create a single action that can be taken
      end
      AccessHelper.create_access(permission_template, 'user', :manage, evaluator.manage_users) if evaluator.manage_users.present?
      AccessHelper.create_access(permission_template, 'group', :manage, evaluator.manage_groups) if evaluator.manage_groups.present?
      AccessHelper.create_access(permission_template, 'user', :deposit, evaluator.deposit_users) if evaluator.deposit_users.present?
      AccessHelper.create_access(permission_template, 'group', :deposit, evaluator.deposit_groups) if evaluator.deposit_groups.present?
      AccessHelper.create_access(permission_template, 'user', :view, evaluator.view_users) if evaluator.view_users.present?
      AccessHelper.create_access(permission_template, 'group', :view, evaluator.view_groups) if evaluator.view_groups.present?
    end

    transient do
      with_admin_set { false }
      with_collection { false }
      with_workflows { false }
      with_active_workflow { false }
      manage_users { nil }
      manage_groups { nil }
      deposit_users { nil }
      deposit_groups { nil }
      view_users { nil }
      view_groups { nil }
    end
  end

  class AccessHelper
    def self.create_access(permission_template_id, agent_type, access, agent_ids)
      agent_ids.each do |agent_id|
        FactoryBot.create(:permission_template_access,
                          access,
                          permission_template: permission_template_id,
                          agent_type: agent_type,
                          agent_id: agent_id)
      end
    end
  end

  class SourceFinder
    def self.find_or_create_admin_set(source_id)
      Hyrax.config.use_valkyrie? ? find_or_create_admin_set_valkyrie(source_id) : find_or_create_admin_set_active_fedora(source_id)
    end

    def self.find_or_create_admin_set_active_fedora(source_id)
      if source_id.present?
        begin
          AdminSet.find(source_id)
        rescue ActiveFedora::ObjectNotFoundError
          FactoryBot.create(:admin_set, id: source_id)
        end
      else
        FactoryBot.create(:admin_set)
      end
    end

    def self.find_or_create_admin_set_valkyrie(source_id)
      if source_id.present?
        begin
          Hyrax.query_service.find_by(id: source_id)
        rescue Valkyrie::Persistence::ObjectNotFoundError
          # Creating an Administrative set with a pre-determined id will not work for all adapters
          # so we're letting the adapter assign the id
          FactoryBot.valkyrie_create(:hyrax_admin_set)
        end
      else
        FactoryBot.valkyrie_create(:hyrax_admin_set)
      end
    end
  end
end
