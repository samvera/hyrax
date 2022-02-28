# frozen_string_literal: true
RSpec.describe Hyrax::ControlledVocabularies::Location do
  let(:rdf_subject) { 'https://sws.geonames.org/5037649/' }
  let(:location) { described_class.new(rdf_subject) }

  before do
    stub_request(:get, 'http://www.geonames.org/getJSON')
      .with(query: hash_including({ 'geonameId': '5037649' }))
      .to_return(status: 200, body: File.open(File.join(fixture_path, 'geonames.json')))
  end

  context 'when indexed' do
    it 'retrieves the full label' do
      expect(location.solrize).to eq [rdf_subject, { label: "Minneapolis, Minnesota, United States$#{rdf_subject}" }]
    end
  end
end
