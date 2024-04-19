# frozen_string_literal: true
FactoryBot.define do
  factory :sipity_entity, class: Sipity::Entity do
    transient do
      proxy_for { nil }
    end

    proxy_for_global_id { 'gid://internal/Mock/1' }
    workflow { workflow_state.workflow }
    workflow_state

    after(:build) do |entity, evaluator|
      entity.proxy_for_global_id = Hyrax::GlobalID(evaluator.proxy_for).to_s if
        evaluator.proxy_for
    end
  end
end
