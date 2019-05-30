
RSpec.describe Hyrax::Indexing::Solr do
  describe ".index_field_mapper" do
    it "constructs a new FieldMapper object" do
      expect(described_class.index_field_mapper).to be_a Hyrax::Indexing::FieldMapper
    end
  end
end
