FactoryGirl.define do
  factory :collection do
    transient do
      user { FactoryGirl.create(:user) }
    end
    sequence(:title) { |n| "Title #{n}" }
    before(:create) { |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    }

    factory :public_collection do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    factory :private_collection do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
  end
end
