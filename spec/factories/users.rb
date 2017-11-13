FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'password'

    transient do
      # Allow for custom groups when a user is instantiated.
      # @example create(:user, groups: 'avacado')
      groups []
    end

    # TODO: Register the groups for the given user key such that we can remove the following from other specs:
    #   `allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin'])``
    after(:build) do |user, evaluator|
      # In case we have the instance but it has not been persisted
      ::RSpec::Mocks.allow_message(user, :groups).and_return(Array.wrap(evaluator.groups))
      # Given that we are stubbing the class, we need to allow for the original to be called
      ::RSpec::Mocks.allow_message(user.class.group_service, :fetch_groups).and_call_original
      # We need to ensure that each instantiation of the admin user behaves as expected.
      # This resolves the issue of both the created object being used as well as re-finding the created object.
      ::RSpec::Mocks.allow_message(user.class.group_service, :fetch_groups).with(user: user).and_return(Array.wrap(evaluator.groups))
    end

    factory :admin do
      groups ['admin']
    end

    factory :user_with_mail do
      after(:create) do |user|
        # Create examples of single file successes and failures
        (1..10).each do |number|
          file = MockFile.new(number.to_s, "Single File #{number}")
          User.batch_user.send_message(user, 'File 1 could not be updated. You do not have sufficient privileges to edit it.', file.to_s, false)
          User.batch_user.send_message(user, 'File 1 has been saved', file.to_s, false)
        end

        # Create examples of mulitple file successes and failures
        files = []
        (1..50).each do |number|
          files << MockFile.new(number.to_s, "File #{number}")
        end
        User.batch_user.send_message(user, 'These files could not be updated. You do not have sufficient privileges to edit them.', 'Batch upload permission denied', false)
        User.batch_user.send_message(user, 'These files have been saved', 'Batch upload complete', false)
      end
    end
  end

  trait :guest do
    guest true
  end
end

class MockFile
  attr_accessor :to_s, :id
  def initialize(id, string)
    self.id = id
    self.to_s = string
  end
end
