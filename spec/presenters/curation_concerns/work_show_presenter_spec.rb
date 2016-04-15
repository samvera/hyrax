require 'spec_helper'

describe CurationConcerns::WorkShowPresenter do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:date_value) { Date.today }
  let(:date_index) { date_value.to_s }
  let(:attributes) do
    { "title_tesim" => ["foo bar"],
      "human_readable_type_tesim" => ["Generic Work"],
      "has_model_ssim" => ["GenericWork"],
      "date_created_tesim" => ['an unformatted date'],
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

  describe "#date_created" do
    subject { presenter.date_created }
    it { is_expected.to eq('an unformatted date') }
  end

  [:date_modified, :date_uploaded].each do |date_field|
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
      expect(Deprecation).to receive(:warn)
      expect(presenter.file_presenters.map(&:id)).to eq obj.ordered_member_ids
    end
  end

  describe "#file_set_presenters" do
    let(:obj) { create(:work_with_ordered_files) }
    let(:attributes) { obj.to_solr }

    it "displays them in order" do
      expect(obj.ordered_member_ids).not_to eq obj.member_ids
      expect(presenter.file_set_presenters.map(&:id)).to eq obj.ordered_member_ids
    end

    context "when some of the members are not file sets" do
      let(:another_work) { create(:work) }
      before do
        obj.ordered_members << another_work
        obj.save!
      end

      it "filters out members that are not file sets" do
        expect(presenter.file_set_presenters.map(&:id)).not_to include another_work.id
      end
    end

    describe "getting presenters from factory" do
      let(:attributes) { {} }
      let(:presenter_class) { double }
      before do
        allow(presenter).to receive(:file_presenter_class).and_return(presenter_class)
        allow(presenter).to receive(:ordered_ids).and_return(['12', '33'])
        allow(presenter).to receive(:file_set_ids).and_return(['33', '12'])
      end

      it "uses the set class" do
        expect(CurationConcerns::PresenterFactory).to receive(:build_presenters)
          .with(['12', '33'], presenter_class, ability)
        presenter.file_set_presenters
      end
    end
  end

  describe "#collection_presenters" do
    let(:collection) { create(:collection) }
    let(:obj) { create(:work) }
    let(:attributes) { obj.to_solr }

    before do
      collection.ordered_members << obj
      collection.save!
      obj.save!
    end

    it "filters out members that are not file sets" do
      expect(presenter.collection_presenters.map(&:id)).to eq [collection.id]
    end
  end

  describe "#attribute_to_html" do
    let(:presenter) { described_class.new(solr_document, ability) }
    let(:renderer) { double('renderer') }

    context 'with an existing field' do
      before do
        allow(CurationConcerns::AttributeRenderer).to receive(:new)
          .with(:title, "foo bar", {})
          .and_return(renderer)
      end

      it "calls the AttributeRenderer" do
        expect(renderer).to receive(:render)
        presenter.attribute_to_html(:title)
      end
    end

    context "with a field that doesn't exist" do
      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with('CurationConcerns::WorkShowPresenter attempted to render restrictions, but no method exists with that name.')
        presenter.attribute_to_html(:restrictions)
      end
    end
  end
end
