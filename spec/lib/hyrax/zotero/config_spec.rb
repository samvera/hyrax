# frozen_string_literal: true
RSpec.describe Hyrax::Zotero do
  it { is_expected.to respond_to(:config) }

  describe 'configuration' do
    subject { described_class.reload_config! }

    let(:client_key) { 'abc123' }
    let(:client_secret) { '789xyz' }

    before do
      stub_const('ENV',           'ZOTERO_CLIENT_KEY' => client_key,
                                  'ZOTERO_CLIENT_SECRET' => client_secret)
    end

    # Reload the config so other tests don't see the stub_const values
    after { described_class.reload_config! }

    it 'has a client key' do
      expect(subject['client_key']).to eq(client_key)
    end

    it 'has a client secret' do
      expect(subject['client_secret']).to eq(client_secret)
    end
  end
end
