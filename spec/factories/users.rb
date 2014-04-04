FactoryGirl.define do
  # TODO the normal_user should be renamed to :user and :user should be renamed to :jill
  factory :normal_user, :class => User do |u|
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'password'
  end

  factory :user, :class => User do |u|
    email 'jilluser@example.com'
    password 'password'
  end

  factory :archivist, aliases: [:user_with_fixtures], :class => User do |u|
    email 'archivist1@example.com'
    password 'password'
  end

  factory :user_with_mail, :class => User do |u|
    email 'archivist2@example.com'
    password 'password'
    after(:create) do |user|
      message = '<span class="batchid ui-helper-hidden">fake_batch_noid</span>You\'ve got mail.'
      User.batchuser().send_message(user, message, "Sample notification.")
    end
  end

  factory :curator, :class => User do |u|
    email 'curator1@example.com'
    password 'password'
  end
end

