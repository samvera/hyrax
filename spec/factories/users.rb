FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "email-#{srand}@test.com" }
    password 'a password'
    password_confirmation 'a password'
    factory :admin do
      after(:build) do |user|
        def user.groups
          ["admin"]
        end
      end
    end

    # taken from Sufia user factory
    factory :jill do
      email 'jilluser@example.com'
    end

    factory :archivist, aliases: [:user_with_fixtures] do
      email 'archivist1@example.com'
    end

    factory :curator do
      email 'curator1@example.com'
    end

  end

end
