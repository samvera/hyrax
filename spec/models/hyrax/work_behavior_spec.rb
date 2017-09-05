RSpec.describe Hyrax::WorkBehavior do
  before do
    class EssentialWork < ActiveFedora::Base
      include Hyrax::WorkBehavior
    end
  end
  after do
    Object.send(:remove_const, :EssentialWork)
  end

  subject { EssentialWork.new }

  it 'mixes together all the goodness' do
    expect(subject.class.ancestors).to include(::Hyrax::WithFileSets,
                                               ::Hyrax::HumanReadableType,
                                               Hyrax::Noid,
                                               Hyrax::Serializers,
                                               Hydra::WithDepositor,
                                               Hydra::AccessControls::Embargoable,
                                               Solrizer::Common,
                                               Hyrax::Suppressible,
                                               Hyrax::CollectionNesting)
  end

  describe '#to_s' do
    it 'uses the provided titles' do
      subject.title = %w[Hello World]
      expect(subject.to_s).to include 'Hello'
      expect(subject.to_s).to include 'World'
    end
  end

  describe 'human_readable_type' do
    it 'has a default' do
      expect(subject.human_readable_type).to eq 'Essential Work'
    end
    it 'is settable' do
      EssentialWork.human_readable_type = 'Custom Type'
      expect(subject.human_readable_type).to eq 'Custom Type'
    end
  end

  it 'inherits (and extends) to_solr behaviors from superclass' do
    expect(subject.to_solr.keys).to include(:id)
    expect(subject.to_solr.keys).to include('has_model_ssim')
  end

  describe 'indexer' do
    let(:klass) { Class.new }

    it 'is settable' do
      EssentialWork.indexer = klass
      expect(EssentialWork.indexer).to eq klass
    end
  end

  describe '#update_nested_collection_relationship_indices', :with_nested_reindexing do
    it 'will be called after save' do
      expect(Samvera::NestingIndexer).to receive(:reindex_relationships).with(id: kind_of(String))
      subject.save!
    end
  end
end
