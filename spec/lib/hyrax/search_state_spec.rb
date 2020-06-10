# frozen_string_literal: true
RSpec.describe Hyrax::SearchState do
  let(:controller) { CatalogController.new }
  let(:config) { Blacklight::Configuration.new }
  let(:state) { described_class.new({}, config, controller) }

  describe "url_for_document" do
    subject { state.url_for_document(document) }

    context "with a collection" do
      let(:document) { SolrDocument.new(id: '9999', has_model_ssim: ['Collection']) }

      it "returns an array with the route set and doc" do
        expect(subject.first).to be_kind_of ActionDispatch::Routing::RoutesProxy
        expect(subject.last).to eq document
      end
    end
    context "with a work" do
      let(:document) { SolrDocument.new(id: '9999', has_model_ssim: ['GenericWork']) }

      it "returns an array with the route set and doc" do
        expect(subject.first).to be_kind_of ActionDispatch::Routing::RoutesProxy
        expect(subject.last).to eq document
      end
    end
  end
end
