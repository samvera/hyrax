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

    context "when the id is not in the authority" do
      it "returns the id as the fallback label" do
        expect(described_class.label("not-a-known-type")).to eq "not-a-known-type"
      end
    end
  end

  describe "active?" do
    it "is true for a known term" do
      expect(described_class.active?("Video")).to be true
    end

    it "is false for an id not in the authority" do
      expect(described_class.active?("not-a-known-type")).to be false
    end
  end

  describe "include_current_value" do
    let(:render_opts) { [] }
    let(:html_opts)   { { class: 'moomin' } }

    it "preserves an off-authority value as a forced-select option" do
      expect(described_class.include_current_value("not-a-known-type", :idx, render_opts, html_opts))
        .to eq [[['not-a-known-type', 'not-a-known-type']], { class: 'moomin force-select' }]
    end

    it "leaves the options untouched for a known term" do
      expect(described_class.include_current_value("Video", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end

    it "leaves the options untouched when the value is blank" do
      expect(described_class.include_current_value("", :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end
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
