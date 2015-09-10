require 'spec_helper'

describe CurationConcerns::GenericFilePresenter do
  let(:solr_document) { SolrDocument.new("title_tesim" => ["foo bar"],
                                         "human_readable_type_tesim" => ["Generic File"],
                                         "mime_type_tesim" => ['image/jpeg'],
                                         "has_model_ssim" => ["GenericFile"]) }
  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe "#to_s" do
    subject { presenter.to_s }
    it { is_expected.to eq 'foo bar' }
  end

  describe "#human_readable_type" do
    subject { presenter.human_readable_type }
    it { is_expected.to eq 'Generic File' }
  end

  describe "#model_name" do
    subject { presenter.model_name }
    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#to_partial_path" do
    subject { presenter.to_partial_path }
    it { is_expected.to eq 'generic_files/generic_file' }
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
    subject { presenter.first('mime_type_tesim') }
    it { is_expected.to eq 'image/jpeg' }
  end

  describe "date_uploaded" do
    it "delegates to the solr_document" do
      expect(solr_document).to receive(:date_uploaded)
      presenter.date_uploaded
    end
  end
end
