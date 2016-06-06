RSpec.describe Sufia::Statistics::Works::ByResourceType do
  let(:service) { described_class.new }

  describe "#query" do
    before do
      create(:generic_work, resource_type: ['Conference Proceeding'])
      create(:generic_work, resource_type: ['Conference Proceeding'])
      create(:generic_work, resource_type: ['Image'])
      create(:generic_work, resource_type: ['Journal'])
    end

    subject { service.query }

    it "is a list of categories" do
      expect(subject).to eq [{ label: 'Conference Proceeding', data: 2 },
                             { label: 'Image', data: 1 },
                             { label: 'Journal', data: 1 }]
    end
  end
end
