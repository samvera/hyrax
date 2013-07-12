FactoryGirl.define do
  factory :user, :class => User do |u|
    email 'jilluser@example.com'
    password 'password'
  end

  factory :archivist, :class => User do |u|
    email 'archivist1@example.com'
    password 'password'
  end

  factory :user_with_fixtures, :class => User do |u|
    email 'archivist2@example.com'
    password 'password'
  end

  factory :curator, :class => User do |u|
    email 'curator1@example.com'
    password 'password'
  end
end

