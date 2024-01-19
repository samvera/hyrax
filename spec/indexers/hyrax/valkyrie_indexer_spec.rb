# frozen_string_literal: true

RSpec.describe Hyrax::ValkyrieIndexer do
  it "is deprecated" do
    expect(Deprecation).to receive(:warn).with(/Hyrax::ValkyrieIndexer/)
    expect(described_class.new(resource: Hyrax::Resource.new)).to be_a Hyrax::Indexers::ResourceIndexer
  end

  describe ".for" do
    it "is deprecated" do
      expect(Deprecation).to receive(:warn).with(/Hyrax::ValkyrieIndexer\.for/)
      expect(described_class.for(resource: Hyrax::Resource.new)).to be_a Hyrax::Indexers::ResourceIndexer
    end
  end
end
