require 'spec_helper'

describe CurationConcerns::UrlHelper do
  before do
    GenericWork.destroy_all
  end
  let(:profile) { ["{\"datastreams\":{}}"] }
  let(:work) { FactoryGirl.create(:generic_work) }
  let(:document) { SolrDocument.new(work.to_solr) }
  subject { helper.url_for_document document }

  it { should eq "/concern/generic_works/#{work.id}" }
  it "should use the curation_concern namespace" do
    expect(helper.url_for_document document).to eq "/concern/generic_works/#{work.id}"
  end
  context "when document is a CurationConcerns::GenericFile" do
    let(:document) { CurationConcerns::GenericFile.new id: '123' }
    it { should eq "/concern/generic_files/123" }
  end
end

