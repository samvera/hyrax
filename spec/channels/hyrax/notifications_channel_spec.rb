# frozen_string_literal: true
RSpec.describe Hyrax::NotificationsChannel do
  subject { described_class.new(connection, nil) }

  let(:connection) { Hyrax::ApplicationCable::Connection.new(server, {}) }
  let(:server) { ActionCable::Server::Base.new }
  let(:user) { create(:user) }

  before do
    allow(connection).to receive(:find_verified_user).and_return(user)
    connection.connect
  end

  describe '#current_user' do
    it 'has a current user instance from its connection' do
      expect(subject.current_user).to eq user
    end
  end

  describe '#update_locale' do
    let(:data) { { 'locale' => 'zh' } }

    it 'updates the current user instance with the locale' do
      expect { subject.update_locale(data) }.to change { user.preferred_locale }
        .from(nil).to(data['locale'])
    end
  end

  describe '#subscribed' do
    # rubocop:disable RSpec/SubjectStub
    it 'calls #stream_for with the current user instance' do
      expect(subject).to receive(:stream_for).with(user).once
      subject.subscribed
    end
    # rubocop:enable RSpec/SubjectStub
  end

  describe '#unsubscribed' do
    # rubocop:disable RSpec/SubjectStub
    it 'calls #stop_all_streams' do
      expect(subject).to receive(:stop_all_streams).once
      subject.unsubscribed
    end
    # rubocop:enable RSpec/SubjectStub
  end
end
