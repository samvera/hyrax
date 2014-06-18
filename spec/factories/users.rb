FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'password'

    factory :jill do
      email 'jilluser@example.com'
    end

    factory :archivist, aliases: [:user_with_fixtures] do
      email 'archivist1@example.com'
    end

    factory :user_with_mail do
      after(:create) do |user|
        message = '<span class="batchid ui-helper-hidden">fake_batch_noid</span>You\'ve got mail.'
        (1..6).each do |number|
          User.batchuser().send_message(user, message, "Sample notification #{number.to_s}.")
        end
      end
    end

    factory :curator do
      email 'curator1@example.com'
    end
  end
end
