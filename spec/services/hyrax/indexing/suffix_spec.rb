
RSpec.describe Hyrax::Indexing::Suffix do
  subject(:suffix) { described_class.new(*fields) }
  let(:fields) do
    [
      :type,
      :stored,
      :indexed,
      :multivalued
    ]
  end

  describe '#multivalued?' do
    it 'determines if a suffix is multivalued' do
      expect(suffix.multivalued?).to be true
    end
  end

  describe '#stored?' do
    it 'determines if a suffix indicates that a Solr field should have its value stored' do
      expect(suffix.stored?).to be true
    end
  end

  describe '#indexed?' do
    it 'determines if a suffix indicates that a Solr field should have its value indexed' do
      expect(suffix.indexed?).to be true
    end
  end

  describe '#field?' do
    it 'determines if a metadata field is used in the suffix' do
      expect(suffix.field?(:type)).to be true
      expect(suffix.field?(:stored)).to be true
    end
  end

  describe '#data_type' do
    it 'accesses the data type for the suffix' do
      expect(suffix.data_type).to eq(:type)
    end
  end

  describe '#config' do
    # rubocop:disable RSpec/ExampleLength
    it 'accesses the generated configuration' do
      expect(suffix.config).to be_an OpenStruct
      expect(suffix.config.fields).to eq(fields)
      expect(suffix.config.suffix_delimiter).to eq('_')
      expect(suffix.config.stored_suffix).to eq('s')
      expect(suffix.config.indexed_suffix).to eq('i')
      expect(suffix.config.multivalued_suffix).to eq('m')

      type_suffix = suffix.config.type_suffix
      expect(type_suffix.call([:string])).to eq('s')
      expect(type_suffix.call([:symbol])).to eq('s')
      expect(type_suffix.call([:text])).to eq('t')
      expect(type_suffix.call([:text_en])).to eq('te')
      expect(type_suffix.call([:date])).to eq('dt')
      expect(type_suffix.call([:time])).to eq('dt')
      expect(type_suffix.call([:integer])).to eq('i')
      expect(type_suffix.call([:boolean])).to eq('b')
      expect(type_suffix.call([:long])).to eq('lt')
      expect { type_suffix.call([:foo]) }.to raise_error(Hyrax::Indexing::InvalidIndexDescriptor,
                                                         "Invalid datatype `:foo'. Must be one of: :date, :time, :text, :text_en, :string, :symbol, :integer, :boolean")
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
