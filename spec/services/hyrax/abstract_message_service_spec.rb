# frozen_string_literal: true
RSpec.describe Hyrax::AbstractMessageService do
  let(:file_set) { double }
  let(:user) { build(:user) }
  let(:klass) do
    Class.new(described_class) do
      def message
        'You have won!'
      end

      def subject
        'Attention!'
      end
    end
  end

  subject { klass.new(file_set, user) }

  describe '#call' do
    it 'invokes Hyrax::MessengerService to deliver the message' do
      expect(Hyrax::MessengerService).to receive(:deliver)
        .with(::User.audit_user, user, 'You have won!', 'Attention!').once
      subject.call
    end
  end
end
