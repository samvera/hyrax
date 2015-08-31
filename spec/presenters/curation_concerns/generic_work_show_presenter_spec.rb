require 'spec_helper'

describe CurationConcerns::GenericWorkShowPresenter do
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
    subject { presenter.permission_badge }

    context "for a private work" do
      it { is_expected.to eq '<span class="label label-danger" title="Private">Private</span>' }
    end

    context "for a work that is restricted to registered users" do
      let(:attributes) do
        { "title_tesim" => ["foo bar"],
          "human_readable_type_tesim" => ["Generic Work"],
          Hydra.config.permissions.read.group => ['registered'],
          "has_model_ssim" => ["GenericWork"] }
      end

      it { is_expected.to eq '<span class="label label-info" title="Institution Name">Institution Name</span>' }
    end
  end
end
