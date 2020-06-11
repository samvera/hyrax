# frozen_string_literal: true
FactoryBot.define do
  factory :workflow_state, class: Sipity::WorkflowState do
    workflow
    name { 'initial' }
  end
end
