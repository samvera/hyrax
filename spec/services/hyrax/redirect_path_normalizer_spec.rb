# frozen_string_literal: true

RSpec.describe Hyrax::RedirectPathNormalizer do
  describe '.call' do
    subject(:normalize) { described_class.call(input) }

    context 'with nil' do
      let(:input) { nil }
      it { is_expected.to be_nil }
    end

    context 'with an empty string' do
      let(:input) { '' }
      it { is_expected.to eq('') }
    end

    context 'with a path that already meets the canonical form' do
      let(:input) { '/handle/12345/678' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a missing leading slash' do
      let(:input) { 'handle/12345/678' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a trailing slash' do
      let(:input) { '/handle/12345/678/' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with multiple trailing slashes' do
      let(:input) { '/handle/12345/678///' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with surrounding whitespace' do
      let(:input) { '  /handle/12345/678  ' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a query string' do
      let(:input) { '/handle/12345/678?utm_source=foo' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a fragment' do
      let(:input) { '/handle/12345/678#section' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a query string and fragment' do
      let(:input) { '/handle/12345/678?x=1#frag' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a full https URL' do
      let(:input) { 'https://old.example.edu/handle/12345/678' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a full URL including query and fragment' do
      let(:input) { 'https://old.example.edu/handle/12345/678?utm_source=foo#cite' }
      it { is_expected.to eq('/handle/12345/678') }
    end

    context 'with a full URL whose path is empty' do
      let(:input) { 'https://old.example.edu' }
      it { is_expected.to eq('/') }
    end

    context 'with a full URL whose path is /' do
      let(:input) { 'https://old.example.edu/' }
      it { is_expected.to eq('/') }
    end

    context 'with a malformed URL' do
      let(:input) { 'http://[invalid' }
      it 'falls back to the original input (treated as a path)' do
        # `extract_path` rescues URI::InvalidURIError; the fallback path then
        # gets a leading slash added like any other non-slash-prefixed input.
        expect(normalize).to eq('/http://[invalid')
      end
    end

    context 'idempotency' do
      let(:input) { 'https://old.example.edu/handle/12345/678/?x=1' }
      it 'is idempotent: calling twice gives the same result as calling once' do
        once = described_class.call(input)
        twice = described_class.call(once)
        expect(once).to eq(twice)
        expect(once).to eq('/handle/12345/678')
      end
    end
  end
end
