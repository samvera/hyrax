# frozen_string_literal: true
RSpec.describe Hyrax::LocationService do
  let(:service) { described_class.new }

  before do
    stub_request(:get, 'http://www.geonames.org/getJSON')
      .with(query: hash_including({ 'geonameId': '5037649' }))
      .to_return(status: 200, body: File.open(File.join(fixture_path, 'geonames.json')))
  end

  context 'with Geonames uri string' do
    let(:uri) { 'https://sws.geonames.org/5037649/' }

    describe 'full_label' do
      it 'returns a full label' do
        expect(service.full_label(uri)).to eq 'Minneapolis, Minnesota, United States'
      end
    end
  end

  context 'with Geonames uri object' do
    let(:uri) { URI('https://sws.geonames.org/5037649/') }

    describe 'full_label' do
      it 'returns a full label' do
        expect(service.full_label(uri)).to eq 'Minneapolis, Minnesota, United States'
      end
    end
  end

  context 'with invalid type' do
    let(:uri) { 5_037_649 }

    describe 'full_label' do
      it 'returns a full label' do
        expect { service.full_label(uri) }.to raise_error
      end
    end
  end

  context 'with blank object' do
    let(:uri) { nil }

    describe 'full_label' do
      it 'returns a full label' do
        expect(service.full_label(uri)).to eq nil
      end
    end
  end
end
