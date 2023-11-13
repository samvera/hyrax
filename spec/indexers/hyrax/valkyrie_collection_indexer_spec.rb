# frozen_string_literal: true

RSpec.describe Hyrax::ValkyrieCollectionIndexer do
  it "is deprecated" do
    expect(Deprecation).to receive(:warn).with(/Hyrax::ValkyrieCollectionIndexer/)
    expect(Deprecation).to receive(:warn).with(/Hyrax::PcdmCollectionIndexer/)
    expect(described_class.new(resource: Hyrax::PcdmCollection.new)).to be_a Hyrax::Indexers::PcdmCollectionIndexer
  end
end
