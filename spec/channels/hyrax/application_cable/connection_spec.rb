# frozen_string_literal: true
RSpec.describe Hyrax::ApplicationCable::Connection do
  subject { described_class.new(server, env) }

  let(:server) { ActionCable::Server::Base.new }
  let(:env) { {} }

  describe '#connect' do
    # rubocop:disable RSpec/SubjectStub
    before do
      allow(subject).to receive(:user_id).and_return(user_id)
    end
    # rubocop:enable RSpec/SubjectStub

    context 'when user is found' do
      let(:user) { create(:user) }
      let(:user_id) { user.id }

      it 'sets #current_user to the found user instance' do
        expect { subject.connect }.to change { subject.current_user }.from(nil).to(user)
      end
    end

    context 'when user is not found' do
      # rubocop:disable RSpec/SubjectStub
      before do
        allow(subject).to receive(:session).and_raise(NoMethodError)
      end
      # rubocop:enable RSpec/SubjectStub

      let(:user_id) { nil }

      it 'rejects the unauthorized connection' do
        expect { subject.connect }.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end
  end
end
