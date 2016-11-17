FactoryGirl.define do
  factory :admin_set do
    title ['Test admin set title']

    trait :public do
      read_groups ['public']
    end
  end
end
