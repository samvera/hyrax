# frozen_string_literal: true

RSpec.describe Hyrax::ValkyrieFileSetIndexer do
  it "is deprecated" do
    expect(Deprecation).to receive(:warn).with(/Hyrax::ValkyrieFileSetIndexer/)
    expect(described_class.new(resource: Hyrax::FileSet.new)).to be_a Hyrax::Indexers::FileSetIndexer
  end
end
