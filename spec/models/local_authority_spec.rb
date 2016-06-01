describe LocalAuthority, type: :model do
  def harvest_nt
    LocalAuthority.harvest_rdf("genres", [fixture_path + '/genreForms.nt'])
  end

  def harvest_tsv
    LocalAuthority.harvest_tsv("geo", [fixture_path + '/cities15000.tsv'], prefix: 'http://sws.geonames.org/')
  end

  before :all do
    class MyTestRdfDatastream; end
  end

  after :all do
    Object.send(:remove_const, :MyTestRdfDatastream)
  end

  it "harvests an ntriples RDF vocab" do
    harvest_nt
    expect(described_class.count).to eq(1)
    expect(LocalAuthorityEntry.count).to eq(6)
  end
  it "harvests an RDF/XML vocab (w/ an alt predicate)" do
    described_class.harvest_rdf("langs", [fixture_path + '/lexvo.rdf'],
                                format: 'rdfxml',
                                predicate: ::RDF::URI("http://www.w3.org/2008/05/skos#prefLabel"))
    expect(described_class.count).to eq(1)
    expect(LocalAuthorityEntry.count).to eq(35)
  end
  it "harvests TSV vocabs" do
    harvest_tsv
    expect(described_class.count).to eq(1)
    auth = described_class.where(name: "geo").first
    expect(LocalAuthorityEntry.where(local_authority_id: auth.id).first.uri).to start_with('http://sws.geonames.org/')
    expect(LocalAuthorityEntry.count).to eq(149)
  end

  describe "when vocabs are harvested" do
    let(:num_auths)   { described_class.count }
    let(:num_entries) { LocalAuthorityEntry.count }

    before do
      harvest_nt
      harvest_tsv
    end

    it "does not have any initial domain terms" do
      expect(DomainTerm.count).to eq(0)
    end

    it "does not harvest an RDF vocab twice" do
      harvest_nt
      expect(described_class.count).to eq(num_auths)
      expect(LocalAuthorityEntry.count).to eq(num_entries)
    end
    it "does not harvest a TSV vocab twice" do
      harvest_tsv
      expect(described_class.count).to eq(num_auths)
      expect(LocalAuthorityEntry.count).to eq(num_entries)
    end
    it "registers a vocab" do
      described_class.register_vocabulary(MyTestRdfDatastream, "geographic", "geo")
      expect(DomainTerm.count).to eq(1)
    end

    describe "when vocabs are registered" do
      before do
        described_class.register_vocabulary(MyTestRdfDatastream, "geographic", "geo")
        described_class.register_vocabulary(MyTestRdfDatastream, "genre", "genres")
      end

      it "has some domain terms" do
        expect(DomainTerm.count).to eq(2)
      end

      describe "#entries_by_term" do
        let(:query) { 'A' }
        let(:term) { 'genre' }
        let(:model) { 'my_tests' }
        subject { described_class.entries_by_term(model, term, query) }

        context "when the query is empty" do
          let(:query) { '' }
          it { is_expected.to be_nil }
        end

        context "when the model is unregistered" do
          let(:model) { 'my_foobar' }
          it { is_expected.to be_empty }
        end

        context "when the terms is unregistered" do
          let(:term) { 'foobar' }
          it { is_expected.to be_empty }
        end

        context "for subject headings" do
          let(:term) { 'subject' }
          let(:model) { 'generic_works' }

          before do
            SubjectLocalAuthorityEntry.create!(lowerLabel: 'apple', url: 'http://example.com/foo')
          end

          it "returns subject terms" do
            expect(subject.count).to eq 1
          end
        end

        it "returns genre terms" do
          expect(subject.count).to eq 6
        end
      end
    end
  end
end
