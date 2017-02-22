FactoryGirl.define do
  factory :workflow, class: Sipity::Workflow do
    sequence(:name) { |n| "generic_work-#{n}" }
    permission_template
  end
end
