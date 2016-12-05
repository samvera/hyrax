require 'spec_helper'

describe SolrDocument do
  let(:document) { described_class.new(attributes) }

  describe "date_uploaded" do
    let(:attributes) { { 'date_uploaded_dtsi' => "2015-08-31T00:00:00Z" } }
    subject { document.date_uploaded }

    it { is_expected.to eq '08/31/2015' }
  end

  describe "representative_id" do
    let(:attributes) { { Solrizer.solr_name('hasRelatedMediaFragment', :symbol) => ['one'] } }
    subject { document.representative_id }
    it { is_expected.to eq 'one' }
  end

  describe "thumbnail_id" do
    let(:attributes) { { Solrizer.solr_name('hasRelatedImage', :symbol) => ['one'] } }
    subject { document.thumbnail_id }
    it { is_expected.to eq 'one' }
  end

  describe "#suppressed?" do
    let(:attributes) { { 'suppressed_bsi' => suppressed_value } }
    subject { document }
    context 'when true' do
      let(:suppressed_value) { true }
      it { is_expected.to be_suppressed }
    end
    context 'when false' do
      let(:suppressed_value) { false }
      it { is_expected.not_to be_suppressed }
    end
  end

  describe "creator" do
    subject { document.creator }

    context "for a work" do
      let(:attributes) do
        { Solrizer.solr_name('creator') => ['one', 'two'],
          Solrizer.solr_name('has_model', :symbol) => ["GenericWork"] }
      end
      it { is_expected.to eq ['one', 'two'] }
    end

    context "for an admin set" do
      let(:attributes) do
        { Solrizer.solr_name('creator', :symbol) => ['foo@example.com'],
          Solrizer.solr_name('has_model', :symbol) => ["AdminSet"] }
      end
      it { is_expected.to eq ['foo@example.com'] }
    end
  end

  describe "contributor" do
    let(:attributes) { { Solrizer.solr_name('contributor') => ['one', 'two'] } }
    subject { document.contributor }
    it { is_expected.to eq ['one', 'two'] }
  end

  describe "subject" do
    let(:attributes) { { Solrizer.solr_name('subject') => ['one', 'two'] } }
    subject { document.subject }
    it { is_expected.to eq ['one', 'two'] }
  end

  describe "publisher" do
    let(:attributes) { { Solrizer.solr_name('publisher') => ['one', 'two'] } }
    subject { document.publisher }
    it { is_expected.to eq ['one', 'two'] }
  end

  describe "language" do
    let(:attributes) { { Solrizer.solr_name('language') => ['one', 'two'] } }
    subject { document.language }
    it { is_expected.to eq ['one', 'two'] }
  end

  describe "visibility" do
    subject { document.visibility }

    context "when open" do
      let(:attributes) { { 'read_access_group_ssim' => ['public'] } }
      it { is_expected.to eq 'open' }
    end

    context "when authenticated" do
      let(:attributes) { { 'read_access_group_ssim' => ['registered'] } }
      it { is_expected.to eq 'authenticated' }
    end

    context "when restricted" do
      let(:attributes) { {} }
      it { is_expected.to eq 'restricted' }
    end
  end

  describe "#page_count" do
    let(:attributes) { { page_count_tesim: ['1'] } }
    subject { document.page_count }
    it { is_expected.to eq ['1'] }
  end

  describe "#file_title" do
    let(:attributes) { { file_title_tesim: ['title'] } }
    subject { document.file_title }
    it { is_expected.to eq ['title'] }
  end

  describe "#duration" do
    let(:attributes) { { duration_tesim: ['time'] } }
    subject { document.duration }
    it { is_expected.to eq ['time'] }
  end

  describe "#sample_rate" do
    let(:attributes) { { sample_rate_tesim: ['rate'] } }
    subject { document.sample_rate }
    it { is_expected.to eq ['rate'] }
  end
end
