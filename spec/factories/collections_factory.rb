FactoryBot.define do
  factory :collection do
    transient do
      user { create(:user) }
    end
    sequence(:title) { |n| ["Title #{n}"] }

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    to_create do |instance|
      persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      persister.save(resource: instance)
    end

    factory :public_collection, traits: [:public]
    factory :private_collection, traits: [:private]
    factory :institution_collection, traits: [:institution]

    trait :public do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    trait :private do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    trait :institution do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end

    factory :named_collection do
      title ['collection title']
      description ['collection description']
    end
  end
end
