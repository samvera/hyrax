FactoryGirl.define do
  # The ::Collection model is defined in spec/internal/app/models by the
  # curation_concerns:install generator.
  factory :collection do
    transient do
      user { FactoryGirl.create(:user) }
    end

    title 'Test collection title'

    after(:build) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
    end
  end
end
