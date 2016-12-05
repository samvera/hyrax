FactoryGirl.define do
  factory :workflow, class: Sipity::Workflow do
    sequence(:name) { |n| "generic_work-#{n}" }
  end
end
