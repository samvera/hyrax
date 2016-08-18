FactoryGirl.define do
  factory :admin_set do
    sequence(:title) { |n| ["Title #{n}"] }
  end
end
