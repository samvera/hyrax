RSpec.describe Hyrax::AdminSetIndexer do
  let(:indexer) { described_class.new(admin_set) }
  let(:admin_set) { build(:admin_set) }
  let(:doc) do
    {
      'generic_type_sim' => ['Admin Set']
    }
  end

  describe "#generate_solr_document" do
    it "has required fields" do
      expect(indexer.generate_solr_document).to match a_hash_including(doc)
    end
  end
end
