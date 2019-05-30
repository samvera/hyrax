
RSpec.describe Hyrax::Indexing::StringDescriptor do
  subject(:string_descriptor) { described_class.new(suffix) }
  let(:suffix) { 'tesim' }

  describe '#suffix' do
    it 'generates the suffix for the field' do
      expect(string_descriptor.suffix(:string)).to eq('_tesim')
    end
  end
end
