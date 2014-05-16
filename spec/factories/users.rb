FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "email-#{srand}@test.com" }
    password 'a password'
    password_confirmation 'a password'
  end

end
