FactoryGirl.define do
  factory :sipity_entity, class: Sipity::Entity do
    proxy_for_global_id 'gid://internal/Mock/1'
    workflow { workflow_state.workflow }
    workflow_state
  end
end
