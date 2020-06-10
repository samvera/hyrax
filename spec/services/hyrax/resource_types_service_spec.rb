# frozen_string_literal: true
RSpec.describe Hyrax::ResourceTypesService do
  describe "select_options" do
    subject { described_class.select_options }

    it "has a select list" do
      expect(subject.first).to eq ["Article", "Article"]
      expect(subject.size).to eq 20
    end
  end

  describe "label" do
    subject { described_class.label("Video") }

    it { is_expected.to eq 'Video' }
  end

  describe "microdata_type" do
    subject { described_class.microdata_type(id) }

    context "when the id is in the i18n" do
      let(:id) { "Map or Cartographic Material" }

      it { is_expected.to eq 'http://schema.org/Map' }
    end

    context "when the id is not in the i18n" do
      let(:id) { "missing" }

      it { is_expected.to eq 'http://schema.org/CreativeWork' }
    end

    context "when the id is nil" do
      let(:id) { nil }

      it { is_expected.to eq 'http://schema.org/CreativeWork' }
    end
  end
end
