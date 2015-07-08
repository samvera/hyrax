FactoryGirl.define do
  factory :collection do
    transient do
      user { FactoryGirl.create(:user) }
    end
    before(:create) do |collection, evaluator|
      collection.apply_depositor_metadata(evaluator.user.user_key)
    end
  end
end
