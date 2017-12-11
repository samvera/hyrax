module Sipity
  RSpec.describe Notification, type: :model do
    subject { described_class.new }

    it 'will raise an ArgumentError if you provide an invalid #notification_type' do
      expect { subject.notification_type = '__incorrect_name__' }.to raise_error(ArgumentError)
    end

    describe '.valid_notification_types' do
      subject { described_class.valid_notification_types }

      it { is_expected.to eq([described_class::NOTIFICATION_TYPE_EMAIL]) }
    end
  end
end
