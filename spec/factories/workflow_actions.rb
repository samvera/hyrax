FactoryBot.define do
  factory :workflow_action, class: Sipity::WorkflowAction do
    workflow
    name { 'submit' }
  end
end
