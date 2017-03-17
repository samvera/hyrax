FactoryGirl.define do
  factory :permission_template, class: Sufia::PermissionTemplate do
    admin_set_id '88888'
    workflow_name AdminSet::DEFAULT_WORKFLOW_NAME
  end
end
