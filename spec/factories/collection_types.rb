FactoryBot.define do
  factory :collection_type, class: Hyrax::CollectionType do
    sequence(:title) { |n| "Collection Type #{n}" }
    sequence(:machine_id) { |n| "title_#{n}" }

    description { 'Collection type with all options' }
    nestable { true }
    discoverable { true }
    sharable { true }
    brandable { true }
    share_applies_to_new_works { true }
    allow_multiple_membership { true }
    require_membership { false }
    assigns_workflow { false }
    assigns_visibility { false }

    transient do
      creator_user { nil }
      creator_group { nil }
      manager_user { nil }
      manager_group { nil }
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
      nestable { true }
    end

    trait :not_nestable do
      nestable { false }
    end

    trait :discoverable do
      discoverable { true }
    end

    trait :not_discoverable do
      discoverable { false }
    end

    trait :brandable do
      brandable { true }
    end

    trait :not_brandable do
      brandable { false }
    end

    trait :sharable do
      sharable { true }
      share_applies_to_new_works { true }
    end

    trait :sharable_no_work_permissions do
      sharable { true }
      share_applies_to_new_works { false }
    end

    trait :not_sharable do
      sharable { false }
      share_applies_to_new_works { false }
    end

    trait :allow_multiple_membership do
      allow_multiple_membership { true }
    end

    trait :not_allow_multiple_membership do
      allow_multiple_membership { false }
    end
  end

  factory :user_collection_type, class: Hyrax::CollectionType do
    initialize_with { Hyrax::CollectionType.find_or_create_default_collection_type }
  end

  factory :admin_set_collection_type, class: Hyrax::CollectionType do
    initialize_with { Hyrax::CollectionType.find_or_create_admin_set_type }
  end
end
