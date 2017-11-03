FactoryBot.define do
  factory :collection_type, class: Hyrax::CollectionType do
    sequence(:title) { |n| "Title #{n}" }

    description 'Collection type with all options'
    nestable true
    discoverable true
    sharable true
    allow_multiple_membership true
    require_membership false
    assigns_workflow false
    assigns_visibility false

    transient do
      creator_user nil
      creator_group nil
      manager_user nil
      manager_group nil
    end

    after(:create) do |collection_type, evaluator|
      if evaluator.creator_user
        attributes = { hyrax_collection_type_id: collection_type.id,
                       access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS,
                       agent_id: evaluator.creator_user,
                       agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE }
        create(:collection_type_participant, attributes)
      end

      if evaluator.creator_group
        attributes = { hyrax_collection_type_id: collection_type.id,
                       access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS,
                       agent_id: evaluator.creator_group,
                       agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE }
        create(:collection_type_participant, attributes)
      end

      if evaluator.manager_user
        attributes = { hyrax_collection_type_id: collection_type.id,
                       access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS,
                       agent_id: evaluator.manager_user,
                       agent_type: Hyrax::CollectionTypeParticipant::USER_TYPE }
        create(:collection_type_participant, attributes)
      end

      if evaluator.manager_group
        attributes = { hyrax_collection_type_id: collection_type.id,
                       access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS,
                       agent_id: evaluator.manager_group,
                       agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE }
        create(:collection_type_participant, attributes)
      end
    end

    trait :nestable do
      nestable true
    end

    trait :not_nestable do
      nestable false
    end

    trait :discoverable do
      discoverable true
    end

    trait :not_discoverable do
      discoverable false
    end

    trait :sharable do
      sharable true
    end

    trait :not_sharable do
      sharable false
    end

    trait :allow_multiple_membership do
      allow_multiple_membership true
    end

    trait :not_allow_multiple_membership do
      allow_multiple_membership false
    end
  end

  factory :user_collection_type, class: Hyrax::CollectionType do
    title 'User Collection'
    description 'A user oriented collection type'

    nestable true
    discoverable true
    sharable true
    allow_multiple_membership true
    require_membership false
    assigns_workflow false
    assigns_visibility false

    after(:create) do |collection_type, _evaluator|
      attributes = { hyrax_collection_type_id: collection_type.id,
                     access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS,
                     agent_id: ::Ability.registered_group_name,
                     agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE }
      create(:collection_type_participant, attributes)
      attributes = { hyrax_collection_type_id: collection_type.id,
                     access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS,
                     agent_id: ::Ability.admin_group_name,
                     agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE }
      create(:collection_type_participant, attributes)
    end
  end

  factory :admin_set_collection_type, class: Hyrax::CollectionType do
    title 'Admin Set'
    description 'An administrative set collection type'
    nestable false
    discoverable false
    sharable true
    allow_multiple_membership false
    require_membership true
    assigns_workflow true
    assigns_visibility true

    after(:create) do |collection_type, _evaluator|
      attributes = { hyrax_collection_type_id: collection_type.id,
                     access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS,
                     agent_id: ::Ability.admin_group_name,
                     agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE }
      create(:collection_type_participant, attributes)
      attributes = { hyrax_collection_type_id: collection_type.id,
                     access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS,
                     agent_id: ::Ability.admin_group_name,
                     agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE }
      create(:collection_type_participant, attributes)
    end
  end
end
