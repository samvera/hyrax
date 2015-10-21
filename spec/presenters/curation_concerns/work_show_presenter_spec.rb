require 'spec_helper'

describe CurationConcerns::WorkShowPresenter do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    { "title_tesim" => ["foo bar"],
      "human_readable_type_tesim" => ["Generic Work"],
      "has_model_ssim" => ["GenericWork"] }
  end

  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe "#to_s" do
    subject { presenter.to_s }
    it { is_expected.to eq 'foo bar' }
  end

  describe "#human_readable_type" do
    subject { presenter.human_readable_type }
    it { is_expected.to eq 'Generic Work' }
  end

  describe "#model_name" do
    subject { presenter.model_name }
    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#permission_badge" do
    it "calls the PermissionBadge object" do
      expect_any_instance_of(CurationConcerns::PermissionBadge).to receive(:render)
      presenter.permission_badge
    end
  end
end
