FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "email-#{srand}@test.com" }
    password 'a password'
    password_confirmation 'a password'
    factory :admin do
      after(:build) do |user|
        allow(user).to receive(:groups).and_return ["admin"]
      end
    end
  end

end
