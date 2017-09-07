FactoryGirl.define do
  factory :permission_template, class: Hyrax::PermissionTemplate do
    # Given that there is a one to one strong relation between permission_template and admin_set,
    # with a unique index on the source_id, I don't want to have duplication in source_id
    sequence(:source_id) { |n| format("%010d", n) }

    before(:create) do |permission_template, evaluator|
      if evaluator.with_admin_set
        source_id = permission_template.source_id
        admin_set =
          if source_id.present?
            begin
              AdminSet.find(source_id)
            rescue
              create(:admin_set, id: source_id)
            end
          else
            create(:admin_set)
          end
        permission_template.source_id = admin_set.id
      end
    end

    after(:create) do |permission_template, evaluator|
      if evaluator.with_workflows
        Hyrax::Workflow::WorkflowImporter.load_workflow_for(permission_template: permission_template)
        Sipity::Workflow.activate!(permission_template: permission_template, workflow_id: permission_template.available_workflows.pluck(:id).first)
      end
      if evaluator.with_active_workflow
        workflow = create(:workflow, active: true, permission_template: permission_template)
        create(:workflow_action, workflow: workflow) # Need to create a single action that can be taken
      end
    end

    transient do
      with_admin_set false
      with_workflows false
      with_active_workflow false
    end
  end
end
