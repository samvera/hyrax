# frozen_string_literal: true
RSpec.describe Hyrax::PresenterRenderer, type: :view do
  let(:ability) { double }
  let(:document) { SolrDocument.new(data) }
  let(:data) do
    { id: '123', date_created_tesim: 'foo', date_uploaded_tesim: 'bar', has_model_ssim: 'GenericWork' }
  end
  let(:presenter) { Hyrax::WorkShowPresenter.new(document, ability) }
  let(:renderer) { described_class.new(presenter, view) }

  describe "#label" do
    it "calls translate with defaults" do
      expect(renderer).to receive(:t).with(:"generic_work.date_created",
                                           default: [:"defaults.date_created", "Date created"],
                                           scope: :"simple_form.labels")
      renderer.label(:date_created)
    end

    context "of a field with a translation" do
      subject { renderer.label(:date_created) }

      it { is_expected.to eq 'Date Created' }
    end

    context "of a field without a translation" do
      subject { renderer.label(:date_uploaded) }

      it { is_expected.to eq 'Date uploaded' }
    end
  end

  describe "#value" do
    it 'provides an HTML safe string' do
      expect(renderer.value(:date_created)).to be_html_safe
    end
  end
end
