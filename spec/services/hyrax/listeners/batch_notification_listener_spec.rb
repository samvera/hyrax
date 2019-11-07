# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::BatchNotificationListener do
  subject(:listener) { described_class.new }

  describe '#on_batch_created' do
    let(:user)  { create(:user) }
    let(:data)  { { result: :success, user: user, messages: [] } }
    let(:event) { Dry::Events::Event.new(:on_batch_created, data) }
    let(:inbox) { user.mailbox.inbox }

    it 'creates a success message for the user' do
      expect { listener.on_batch_created(event) }
        .to change { inbox.last }
        .to have_attributes subject: 'Passing batch create'
    end

    context 'on failure' do
      let(:data) { { result: :failure, user: user, messages: [] } }

      it 'creates a failure message for the user' do
        expect { listener.on_batch_created(event) }
          .to change { inbox.last }
          .to have_attributes subject: 'Failing batch create'
      end
    end
  end
end
