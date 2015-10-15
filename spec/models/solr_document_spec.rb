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

  describe "creator" do
    let(:attributes) { { Solrizer.solr_name('creator') => ['one', 'two'] } }
    subject { document.creator }
    it { is_expected.to eq ['one', 'two'] }
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
end
