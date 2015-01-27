require 'spec_helper'

describe FeaturedWorkList, :type => :model do
  let(:file1) { create(:generic_file) }
  let(:file2) { create(:generic_file) }

  describe 'featured_works' do
    before do
      create(:featured_work, generic_file_id: file1.id)
      create(:featured_work, generic_file_id: file2.id)
    end

    it 'should be a list of the featured work objects, each with the generic_file\'s solr_doc' do
      expect(subject.featured_works.size).to eq 2
      solr_doc = subject.featured_works.first.generic_file_solr_document
      expect(solr_doc).to be_kind_of SolrDocument
      expect(solr_doc.id).to eq file1.id
    end
  end

  describe 'file deleted' do
    before do
      create(:featured_work, generic_file_id: file1.id)
      create(:featured_work, generic_file_id: file2.id)
      file1.destroy
    end

    it 'should be a list of the remaining featured work objects, each with the generic_file\'s solr_doc' do
      expect(subject.featured_works.size).to eq 1
      solr_doc = subject.featured_works.first.generic_file_solr_document
      expect(solr_doc).to be_kind_of SolrDocument
      expect(solr_doc.id).to eq file2.id
    end
  end

  describe '#empty?' do
    context "when there are featured works" do
      before do
        create(:featured_work, generic_file_id: file1.id)
      end
      it { is_expected.not_to be_empty }
    end

    it { is_expected.to be_empty }
  end
end
