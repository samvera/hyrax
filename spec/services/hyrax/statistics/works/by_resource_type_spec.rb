RSpec.describe Hyrax::Statistics::Works::ByResourceType do
  let(:service) { described_class.new }

  describe "#query", :clean_repo do
    before do
      create(:generic_work, resource_type: ['Conference Proceeding'])
      create(:generic_work, resource_type: ['Conference Proceeding'])
      create(:generic_work, resource_type: ['Image'])
      create(:generic_work, resource_type: ['Journal'])
    end

    subject { service.query }

    it "is a list of categories" do
      expect(subject).to be_an Array
      expect(subject.length).to eq 3
      expect(subject.first).to be_a Hyrax::Statistics::TermQuery::Result
      data = subject.map { |result| JSON.parse(result.to_json) }
      expect(data).to include('label' => 'Conference Proceeding', 'data' => 2)
      expect(data).to include('label' => 'Image', 'data' => 1)
      expect(data).to include('label' => 'Journal', 'data' => 2)
      expect(JSON.parse(subject.to_json)).to eq(data)
    end
  end
end
