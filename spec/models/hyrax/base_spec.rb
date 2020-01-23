# frozen_string_literal: true

RSpec.describe Hyrax::Base do
  describe '.uncached' do
    let(:block) { proc { puts 'I do nothing' } }

    it 'calls ActiveFedora::Base.uncached' do
      allow(ActiveFedora::Base).to receive(:uncached)
      described_class.uncached(&block)
      expect(ActiveFedora::Base).to have_received(:uncached) do |&passed_block|
        expect(passed_block).to eq(block)
      end
    end
  end

  describe '.id_to_uri' do
    let(:id) { 'abc123' }

    it 'calls ActiveFedora::Base.id_to_uri' do
      allow(ActiveFedora::Base).to receive(:id_to_uri)
      described_class.id_to_uri(id)
      expect(ActiveFedora::Base).to have_received(:id_to_uri).with(id).once
    end
  end

  describe '.uri_to_id' do
    let(:uri) { 'https://foo.bar/abc123' }

    it 'calls ActiveFedora::Base.uri_to_id' do
      allow(ActiveFedora::Base).to receive(:uri_to_id)
      described_class.uri_to_id(uri)
      expect(ActiveFedora::Base).to have_received(:uri_to_id).with(uri).once
    end
  end
end
