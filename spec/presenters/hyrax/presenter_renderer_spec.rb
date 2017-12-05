RSpec.describe Hyrax::PresenterRenderer, type: :view do
  let(:work) { create_for_repository(:work) }
  let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: work) }
  let(:ability) { double }
  let(:solr_document) { SolrDocument.new(document) }
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability) }
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
end
