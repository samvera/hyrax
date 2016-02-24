FactoryGirl.define do
  # The ::Collection model is defined in .internal_test_app/app/models by the
  # curation_concerns:install generator.
  factory :collection do
    transient do
      user { FactoryGirl.create(:user) }
    end

    title ['Test collection title']

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
    end

    trait :public do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end
end
