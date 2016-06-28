RSpec.describe LocalSubjects do
  before do
    LocalAuthority.create(name: 'lc_subjects')
    SubjectLocalAuthorityEntry.create(label: 'Hydra', lowerLabel: 'hydra', url: 'http://id.loc.gov/authorities/subjects/sh85063283')
    LocalAuthority.register_vocabulary('generic_works', "subject", "lc_subjects")
  end

  let(:authority) { described_class.new(double) }

  describe "#search" do
    it "returns results" do
      result = authority.search('hyd')
      expect(result).to eq [{ uri: "http://id.loc.gov/authorities/subjects/sh85063283",
                              label: "Hydra" }]
    end
  end
end
