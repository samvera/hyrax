# frozen_string_literal: true
RSpec.describe Hyrax::ApplicationCable::Channel do
  subject { described_class.new(connection, identifier) }

  let(:connection) { double('connection', identifiers: []) }
  let(:identifier) { double }

  describe 'behaves like an ActionCable::Channel::Base' do
    it { is_expected.to respond_to(:perform_action) }
    it { is_expected.to respond_to(:unsubscribe_from_channel) }
    it { is_expected.to respond_to(:stop_all_streams) }
    it { is_expected.to respond_to(:stream_for) }
    it { is_expected.to respond_to(:stream_from) }
  end
end
