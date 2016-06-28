RSpec.describe LocalLanguages do
  before do
    la = LocalAuthority.create(name: 'lexvo_languages')
    la.local_authority_entries.create(label: 'French', uri: 'http://id.loc.gov/languages/fr')
    LocalAuthority.register_vocabulary('generic_works', "language", "lexvo_languages")
  end

  let(:authority) { described_class.new(double) }

  describe "#search" do
    it "returns results" do
      result = authority.search('fre')
      expect(result).to eq [{ uri: "http://id.loc.gov/languages/fr",
                              label: "French" }]
    end
  end
end
