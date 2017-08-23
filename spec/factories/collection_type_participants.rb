FactoryGirl.define do
  factory :collection_type_participant, class: Hyrax::CollectionTypeParticipant do
    association :hyrax_collection_type, factory: :collection_type
    sequence(:agent_id) { |n| "user#{n}@example.com" }
    agent_type  'user'
    access      'manager'
  end
end
