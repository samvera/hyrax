module Sipity
  RSpec.describe NotificationRecipient, type: :model do
    subject { described_class.new }

    it 'will raise an ArgumentError if you provide an invalid recipient_strategy' do
      expect { subject.recipient_strategy = '__incorrect_name__' }.to raise_error(ArgumentError)
    end
  end
end
