# frozen_string_literal: true

RSpec.describe Hyrax::PcdmCollectionIndexer do
  it "is deprecated" do
    expect(Deprecation).to receive(:warn).with(/Hyrax::PcdmCollectionIndexer/)
    described_class.new(resource: Hyrax::PcdmCollection.new)
  end
end
