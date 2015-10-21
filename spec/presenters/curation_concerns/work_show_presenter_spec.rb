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

  describe "#file_presenters" do
    before do
      class TestConcern < ActiveFedora::Base
        include ::CurationConcerns::WorkBehavior
        include ::CurationConcerns::BasicMetadata
      end
    end
    after do
      Object.send(:remove_const, :TestConcern)
    end
    let(:obj) { FactoryGirl.create(:work_with_ordered_files) }
    let(:presenter) { described_class.new(SolrDocument.new(obj.to_solr), ability) }

    it "displays them in order" do
      expect(obj.ordered_member_ids).not_to eq obj.member_ids
      expect(presenter.file_presenters.map(&:id)).to eq obj.ordered_member_ids
    end
  end
end
