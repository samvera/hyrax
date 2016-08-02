require 'spec_helper'

describe CurationConcerns::FileSetPresenter do
  let(:solr_document) { SolrDocument.new("title_tesim" => ["foo bar"],
                                         "human_readable_type_tesim" => ["File Set"],
                                         "mime_type_ssi" => 'image/jpeg',
                                         'label_tesim' => ['one', 'two'],
                                         "has_model_ssim" => ["FileSet"]) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe "#to_s" do
    subject { presenter.to_s }
    it { is_expected.to eq 'foo bar' }
  end

  describe "#human_readable_type" do
    subject { presenter.human_readable_type }
    it { is_expected.to eq 'File Set' }
  end

  describe "#model_name" do
    subject { presenter.model_name }
    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#to_partial_path" do
    subject { presenter.to_partial_path }
    it { is_expected.to eq 'file_sets/file_set' }
  end

  describe "office_document?" do
    subject { presenter.office_document? }
    it { is_expected.to be false }
  end

  describe "has?" do
    subject { presenter.has?('thumbnail_path_ss') }
    it { is_expected.to be false }
  end

  describe "first" do
    subject { presenter.first('human_readable_type_tesim') }
    it { is_expected.to eq 'File Set' }
  end

  describe "properties delegated to solr_document" do
    let(:solr_properties) do
      ["date_uploaded", "depositor", "keyword", "title_or_label",
       "contributor", "creator", "title", "description", "publisher",
       "subject", "language", "rights"]
    end
    it "delegates to the solr_document" do
      solr_properties.each do |property|
        expect(solr_document).to receive(property.to_sym)
        presenter.send(property)
      end
    end
  end

  describe "fetch" do
    it "delegates to the solr_document" do
      expect(solr_document).to receive(:fetch).and_call_original
      expect(presenter.fetch("has_model_ssim")).to eq ["FileSet"]
    end
  end

  describe "#link_name" do
    subject { presenter.link_name }
    context "when it's readable" do
      before { allow(ability).to receive(:can?).and_return(true) }
      it { is_expected.to eq 'one' }
    end

    context "when it's not readable" do
      before { allow(ability).to receive(:can?).and_return(false) }
      it { is_expected.to eq 'File' }
    end
  end

  describe "#single_use_links" do
    let!(:show_link)     { create(:show_link, itemId: presenter.id) }
    let!(:download_link) { create(:download_link, itemId: presenter.id) }
    subject { presenter.single_use_links }
    it { is_expected.to include(CurationConcerns::SingleUseLinkPresenter) }
  end
end
