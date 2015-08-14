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
  it 'uses the curation_concern namespace' do
    expect(helper.url_for_document document).to eq "/concern/generic_works/#{work.id}"
  end
  context 'when document is a GenericFile' do
    let(:file) { FactoryGirl.create(:generic_file) }
    subject { helper.url_for_document file }
    it { should eq "/concern/generic_files/#{file.id}" }
  end
end
