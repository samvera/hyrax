RSpec.describe Hyrax::HumanReadableTypeIndexer do
  subject(:solr_document) { service.to_solr }

  let(:service) { described_class.new(resource: work) }
  let(:work) { build(:work) }

  it 'indexes thumbnail path' do
    expect(solr_document.fetch(:human_readable_type_tesim)).to eq "Generic Work"
    expect(solr_document.fetch(:human_readable_type_sim)).to eq "Generic Work"
  end
end
