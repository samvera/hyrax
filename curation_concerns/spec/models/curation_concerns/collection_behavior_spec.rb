require 'spec_helper'
require 'rspec/active_model/mocks'

describe CurationConcerns::CollectionBehavior do
  include CurationConcerns::FactoryHelpers

  # All behavior for Collection are defined in CC::CollectionBehavior, so we use
  # a Collection instance to test.
  let(:collection) { FactoryGirl.build(:collection) }
  subject { collection }

  it 'does not allow a collection to be saved without a title' do
    subject.title = nil
    expect { subject.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end

  describe "indexer" do
    subject { Collection.indexer }
    it { is_expected.to eq CurationConcerns::CollectionIndexer }
  end

  describe '.bytes' do
    subject { collection.bytes }

    context 'with no items' do
      before { collection.save }
      it "gets zero without querying solr" do
        expect(ActiveFedora::SolrService).not_to receive(:query)
        is_expected.to eq 0
      end
    end

    # Calculating the size of the Collection should only hit Solr.
    # This base case querries solr in an integration test
    context 'with indexed Works and FileSets', :integration do
      let(:file1) { FactoryGirl.build(:file_set) }
      let(:file2) { FactoryGirl.build(:file_set) }
      let(:file3) { FactoryGirl.build(:file_set, id: 'fumid') }
      let(:work1) { FactoryGirl.build(:generic_work) }
      let(:work2) { FactoryGirl.build(:generic_work) }
      let(:work3) { FactoryGirl.build(:generic_work, id: 'dumid') }
      let(:of1)   { mock_file_factory(file_size: ['100']) }
      let(:of2)   { mock_file_factory(file_size: ['100']) }
      let(:of3)   { mock_file_factory(file_size: ['9000']) }

      before do
        allow(file1).to receive(:original_file).and_return(of1)
        allow(file2).to receive(:original_file).and_return(of2)
        allow(file3).to receive(:original_file).and_return(of3)
        # Save collection to get ids
        collection.save
        # Create relationships so member_ids are created
        collection.members = [work1, work2]
        work1.members = [file1]
        work2.members = [file2]
        # Create a relatinship not in the collection.
        # mock member_of relationship to avoid load_from_fedora
        allow(file3).to receive(:generic_work_ids).and_return([work3.id])
        work3.members = [file3]

        # Manually Call Indexing to put the data in Solr
        ActiveFedora::SolrService.add(collection.to_solr)
        ActiveFedora::SolrService.add(work1.to_solr, softCommit: true)
        ActiveFedora::SolrService.add(work2.to_solr, softCommit: true)
        ActiveFedora::SolrService.add(work3.to_solr, softCommit: true)
        ActiveFedora::SolrService.add(file1.to_solr, softCommit: true)
        ActiveFedora::SolrService.add(file2.to_solr, softCommit: true)
        ActiveFedora::SolrService.add(file3.to_solr, softCommit: true)
      end

      it "is the correct aggregate size" do
        is_expected.to eq 200
      end
    end
  end

  describe 'intrinsic properties' do
    let(:collection1) { FactoryGirl.build(:collection) }
    let(:work1) { FactoryGirl.build(:work) }

    it 'is a pcdm:Collection' do
      expect(subject.pcdm_collection?).to be true
      expect(subject.type).to include Hydra::PCDM::Vocab::PCDMTerms.Collection
    end

    it 'is not a pcdm:Object' do
      expect(subject.pcdm_object?).to be false
      expect(subject.type).to_not include Hydra::PCDM::Vocab::PCDMTerms.Object
    end

    it 'contains objects' do
      expect(subject.works).to eq []
      expect(subject.work_ids).to eq []
      expect(subject.members << work1).to eq [work1]
      expect(subject.works).to eq [work1]
      expect(subject.work_ids).to eq [work1.id]
    end

    it 'contains collections' do
      expect(subject.collections).to eq []
      expect(subject.collection_ids).to eq []
      expect(subject.members << collection1).to eq [collection1]
      expect(subject.collections).to eq [collection1]
      expect(subject.collection_ids).to eq [collection1.id]
    end
    it 'has related objects' do
      expect(subject.related_objects).to eq []
      expect(subject.related_objects << work1).to eq [work1]
      expect(subject.related_objects).to eq [work1]
    end
    it 'has parent collections' do
      expect(subject.in_collections).to eq []
      expect(collection1.members << subject).to eq [subject]
      # Function of auto-save/indexing issues.
      subject.save
      collection1.save
      expect(subject.in_collections).to eq [collection1]
    end
  end
end
