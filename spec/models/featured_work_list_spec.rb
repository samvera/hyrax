require 'spec_helper'

describe FeaturedWorkList, :type => :model do
  let(:file1) { FactoryGirl.create(:generic_file) }
  let(:file2) { FactoryGirl.create(:generic_file) }

  before do
    FeaturedWork.create(generic_file_id: file1.noid)
    FeaturedWork.create(generic_file_id: file2.noid)
  end

  after { GenericFile.destroy_all }

  describe 'featured_works' do
    it 'should be a list of the featured work objects, each with the generic_file\'s solr_doc' do
      expect(subject.featured_works.size).to eq 2
      solr_doc = subject.featured_works.first.generic_file_solr_document
      expect(solr_doc).to be_kind_of SolrDocument
      expect(solr_doc.noid).to eq file1.noid 
    end 
  end
end
