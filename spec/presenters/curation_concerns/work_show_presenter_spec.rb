require 'spec_helper'

describe CurationConcerns::WorkShowPresenter do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:date_value) { Date.today }
  let(:date_index) { date_value.to_s }
  let(:attributes) do
    { "title_tesim" => ["foo bar"],
      "human_readable_type_tesim" => ["Generic Work"],
      "has_model_ssim" => ["GenericWork"],
      "date_created_dtsi" => date_index,
      "date_modified_dtsi" => date_index,
      "date_uploaded_dtsi" => date_index }
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

  [:date_created, :date_modified, :date_uploaded].each do |date_field|
    describe "##{date_field}" do
      subject { presenter.send date_field }
      it { is_expected.to eq date_value.to_formatted_s(:standard) }
    end
  end

  describe "#permission_badge" do
    it "calls the PermissionBadge object" do
      expect_any_instance_of(CurationConcerns::PermissionBadge).to receive(:render)
      presenter.permission_badge
    end
  end

  describe "#file_presenters" do
    let(:obj) { create(:work_with_ordered_files) }
    let(:attributes) { obj.to_solr }

    it "displays them in order" do
      expect(obj.ordered_member_ids).not_to eq obj.member_ids
      expect(presenter.file_presenters.map(&:id)).to eq obj.ordered_member_ids
    end

    describe "getting presenters from factory" do
      let(:attributes) { {} }
      let(:presenter_class) { double }
      before do
        allow(presenter).to receive(:file_presenter_class).and_return(presenter_class)
        allow(presenter).to receive(:ordered_ids).and_return(['12', '33'])
      end

      it "uses the set class" do
        expect(CurationConcerns::PresenterFactory).to receive(:build_presenters)
          .with(['12', '33'], presenter_class, ability)
        presenter.file_presenters
      end
    end
  end
end
