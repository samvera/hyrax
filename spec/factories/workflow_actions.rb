# frozen_string_literal: true
FactoryBot.define do
  factory :workflow_action, class: Sipity::WorkflowAction do
    workflow
    name { 'submit' }
  end
end
