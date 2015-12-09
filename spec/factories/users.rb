FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'password'

    factory :user_with_mail do
      after(:create) do |user|
        # TODO: what is this class for?
        # <span class="batchid ui-helper-hidden">fake_upload_set_id</span>
        message = UploadSetMessage.new

        # Create examples of single file successes and failures
        (1..10).each do |number|
          file = MockFile.new(number.to_s, "Single File #{number}")
          User.batchuser.send_message(user, message.single_success("single-batch-success", file), message.success_subject, false)
          User.batchuser.send_message(user, message.single_failure("single-batch-failure", file), message.failure_subject, false)
        end

        # Create examples of mulitple file successes and failures
        files = []
        (1..50).each do |number|
          files << MockFile.new(number.to_s, "File #{number}")
        end
        User.batchuser.send_message(user, message.multiple_success("multiple-batch-success", files), message.success_subject, false)
        User.batchuser.send_message(user, message.multiple_failure("multiple-batch-failure", files), message.failure_subject, false)
      end
    end
  end
end

class MockFile
  attr_accessor :to_s, :id
  def initialize(id, string)
    self.id = id
    self.to_s = string
  end
end

class UploadSetMessage
  include Sufia::Messages
end
