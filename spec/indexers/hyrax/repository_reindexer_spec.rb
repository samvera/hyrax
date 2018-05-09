RSpec.describe Hyrax::RepositoryReindexer do
  let(:subject) { Samvera::NestingIndexer }

  it 'overrides ActiveFedora#reindex_everything' do
    expect(subject).to receive(:reindex_all!).with(extent: Hyrax::Adapters::NestingIndexAdapter::FULL_REINDEX)
    ActiveFedora::Base.reindex_everything
  end
end
