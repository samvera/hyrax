FactoryGirl.define do
  factory :admin_set do
    sequence(:title) { |n| ["Title #{n}"] }
  end

  trait :public do
    read_groups ['public']
  end
end
