
RSpec.describe Hyrax::Indexing::Descriptor do
  subject(:descriptor) { described_class.new(*args) }
  let(:args) do
    [
      {
        converter: nil,
        requires_type: true
      }
    ]
  end

  describe '#name_and_converter' do
    it 'generates the values for indexing field values into Solr' do
      expect { descriptor.name_and_converter(:subject) }.to raise_error(ArgumentError, "Must provide a :type argument when index_type is `#{descriptor}' for subject")
    end
  end

  describe '#type_required?' do
    it 'determines if this type of descriptor is required for indexing' do
      expect(descriptor.type_required?).to be true
    end
  end
end
