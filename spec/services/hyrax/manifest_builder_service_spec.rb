# frozen_string_literal: true

RSpec.describe Hyrax::ManifestBuilderService, :clean_repo do
  # Presenters requires a whole lot of context and therefore a whole lot of preamble
  let(:id) { "123" }
  let(:title) { ["A Title"] }
  let(:description) { ["A Treatise on Coding in Samvera"] }
  let(:creator) { ["An Author"] }
  let(:rights_statement) { ["http://rightsstatements.org/vocab/InC/1.0/"] }
  let(:solr_document) do
    SolrDocument.new(
      id: id,
      has_model_ssim: ["GenericWork"],
      title_tesim: title,
      description_tesim: description,
      creator_tesim: creator,
      rights_statement_tesim: rights_statement
    )
  end
  let(:presenter) { Hyrax::IiifManifestPresenter.new(solr_document) }
  subject { described_class.manifest_for(presenter: presenter) }

  describe ".as_json" do
    it "will be a Ruby hash" do
      expect(Rails.cache).not_to receive(:fetch)
      expect(subject).to be_a(Hash)
    end
  end

  context "V2 manifest" do
    subject do
      described_class.manifest_for(presenter: presenter, iiif_manifest_factory: IIIFManifest::ManifestFactory)
    end

    describe "sanitization" do
      let(:title) { "M&M's" }
      let(:description) { ["A <script>alert('malicious code')</script>Treatise on Coding in Samvera"] }
      let(:creator) { ["An <script>alert('malicious code')</script>Author"] }

      it "sanitizes HTML from text fields" do
        expect(subject["label"]).to eq "M&M's" # does not change & to &amp;
        expect(subject["description"]).to eq "A Treatise on Coding in Samvera"
        expect(subject["metadata"].find { |hash| hash["label"] == "Creator" }["value"]).to eq ["An Author"]
      end
    end
  end

  context "V3 manifest" do
    subject do
      described_class.manifest_for(presenter: presenter, iiif_manifest_factory: IIIFManifest::V3::ManifestFactory)
    end

    describe "sanitization" do
      let(:title) { "M&M's" }
      let(:description) { ["A <script>alert('malicious code')</script>Treatise on Coding in Samvera"] }
      let(:creator) { ["An <script>alert('malicious code')</script>Author"] }

      it "sanitizes HTML from text fields" do
        expect(subject["label"].values.first.first).to eq "M&M's" # does not change & to &amp;
        expect(subject["summary"].values.first.first).to eq "A Treatise on Coding in Samvera"
        expect(
          subject["metadata"].find { |hash| hash["label"].values.first.first == "Creator" }["value"].values.first
        ).to eq ["An Author"]
      end
    end
  end
end
