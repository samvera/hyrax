FactoryGirl.define do
  factory :admin_set do
    sequence(:title) { |n| ["Title #{n}"] }

    after(:create) do |admin_set|
      create(:permission_template, admin_set_id: admin_set.id)
    end
  end

  trait :public do
    read_groups ['public']
  end
end
