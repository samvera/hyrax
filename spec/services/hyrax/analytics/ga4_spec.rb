# frozen_string_literal: true
RSpec.describe Hyrax::Analytics::Ga4 do
  describe Hyrax::Analytics::Ga4::ConfigurationError do
    it 'is the parent of the account JSON errors' do
      expect(Hyrax::Analytics::Ga4::InvalidAccountJson.ancestors).to include(described_class)
      expect(Hyrax::Analytics::Ga4::AccountJsonFileError.ancestors).to include(described_class)
    end
  end

  describe 'Config#account_info' do
    subject(:config) { described_class::Config.new(settings) }

    let(:valid_json) { { 'type' => 'service_account' }.to_json }

    context 'with account_json that parses' do
      let(:settings) { { 'account_json' => valid_json } }

      it { expect(config.account_info).to eq('type' => 'service_account') }
    end

    context 'with account_json that is not valid JSON' do
      let(:settings) { { 'account_json' => '{"private_key": "SECRET-KEY-TEXT" oops' } }

      it 'raises InvalidAccountJson without quoting the input' do
        expect { config.account_info }.to raise_error(described_class::InvalidAccountJson) { |error|
          expect(error.message).not_to include('SECRET-KEY-TEXT')
          expect(error.cause).to be_a(JSON::ParserError)
        }
      end
    end

    context 'with an account_json_path to a readable file' do
      let(:file) { Tempfile.new(['account', '.json']).tap { |f| f.write(valid_json) && f.flush } }
      let(:settings) { { 'account_json_path' => file.path } }

      it { expect(config.account_info).to eq('type' => 'service_account') }
    end

    context 'with an account_json_path to a missing file' do
      let(:settings) { { 'account_json_path' => '/nonexistent/google-account.json' } }

      it 'raises AccountJsonFileError without the path' do
        expect { config.account_info }.to raise_error(described_class::AccountJsonFileError) { |error|
          expect(error.message).not_to include('/nonexistent')
          expect(error.cause).to be_a(Errno::ENOENT)
        }
      end
    end
  end
end
