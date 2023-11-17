# frozen_string_literal: true

RSpec.describe Hyrax::ValkyrieWorkIndexer do
  it "is deprecated" do
    expect(Deprecation).to receive(:warn).with(/Hyrax::ValkyrieWorkIndexer/)
    expect(described_class.new(resource: Hyrax::Work.new)).to be_a Hyrax::Indexers::PcdmObjectIndexer
  end
end
