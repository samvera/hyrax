require 'spec_helper'

describe CurationConcerns::PresenterFactory do
  describe "#build_presenters" do
    let(:presenter_class) { CurationConcerns::FileSetPresenter }

    before do
      allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}12,13", rows: 1000).and_return(results)
    end

    subject { described_class.build_presenters(['12', '13'], presenter_class, nil) }

    context "when some ids are found in solr" do
      let(:results) { [{ "id" => "12" }, { "id" => "13" }] }
      it "has two results" do
        expect(subject.size).to eq 2
      end
    end

    context "when some ids are not found in solr" do
      let(:results) { [{ "id" => "13" }] }
      it "has one result" do
        expect(subject.size).to eq 1
      end
    end
  end
end
