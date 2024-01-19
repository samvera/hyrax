# frozen_string_literal: true

RSpec.describe Hyrax::AdministrativeSetIndexer do
  it "is deprecated" do
    expect(Deprecation).to receive(:warn).with(/Hyrax::AdministrativeSetIndexer/)
    expect(described_class.new(resource: Hyrax::AdministrativeSet.new)).to be_a Hyrax::Indexers::AdministrativeSetIndexer
  end
end
