require 'spec_helper'

describe CurationConcerns::UrlHelper do
  subject { helper.url_for_document(document) }

  context 'when document is a SolrDocument that points at a Work' do
    let(:work) { create(:generic_work) }
    let(:document) { SolrDocument.new(work.to_solr) }
    it "forms the correct path" do
      expect(polymorphic_path(subject)).to eq "/concern/generic_works/#{work.id}"
    end
  end

  context 'when document is a FileSet' do
    let(:document) { create(:file_set) }
    it "forms the correct path" do
      expect(polymorphic_path(subject)).to eq "/concern/file_sets/#{document.id}"
    end
  end
end
