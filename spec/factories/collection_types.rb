FactoryGirl.define do
  factory :collection_type, class: Hyrax::CollectionType do
    sequence(:id) { |n| format("%010d", n) }
    sequence(:title) { |n| "Title #{n}" }

    description 'Collection type with all options'
    nestable true
    discoverable true
    sharable true
    allow_multiple_membership true
    require_membership false
    assigns_workflow false
    assigns_visibility false

    factory :user_collection_type do
      title 'User Collection'
      description 'A user oriented collection type'
    end

    factory :admin_set_collection_type do
      title 'Admin Set'
      description 'An administrative set collection type'
      nestable false
      discoverable false
      sharable true
      allow_multiple_membership false
      require_membership true
      assigns_workflow true
      assigns_visibility true
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
end
