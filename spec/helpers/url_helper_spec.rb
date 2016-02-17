require 'spec_helper'

describe CurationConcerns::UrlHelper do
  let(:profile) { ["{}"] }
  let(:work) { create(:generic_work) }
  let(:document) { SolrDocument.new(work.to_solr) }
  subject { helper.url_for_document document }

  it { is_expected.to eq "/concern/generic_works/#{work.id}" }

  it 'uses the curation_concern namespace' do
    expect(helper.url_for_document(document)).to eq "/concern/generic_works/#{work.id}"
  end

  context 'when document is a FileSet' do
    let(:file) { create(:file_set) }
    subject { helper.url_for_document file }
    it { is_expected.to eq "/concern/file_sets/#{file.id}" }
  end
end
