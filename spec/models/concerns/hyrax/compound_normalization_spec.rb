# frozen_string_literal: true

RSpec.describe Hyrax::CompoundNormalization do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestNormalizedCompoundResource'
      end

      attribute :contributors,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: { 'given_name' => { 'type' => 'string' } }
                )

      include Hyrax::CompoundNormalization
    end
  end

  describe '.compound_attribute_names' do
    it 'derives the compound list from the schema' do
      expect(resource_class.compound_attribute_names).to contain_exactly(:contributors)
    end
  end

  describe 'read-path normalization' do
    it 'collapses a multi-key splayed pair array back into a hash' do
      # This is the shape JSONValueMapper produces on reload of a single entry:
      # the persisted [{given_name:, family:}] is unwrapped and splayed to pairs.
      expect(Hyrax::CompoundNormalization.normalize_compound([[:given_name, 'Ada'], [:family, 'Lovelace']]))
        .to eq([{ 'given_name' => 'Ada', 'family' => 'Lovelace' }])
    end

    it 'leaves a well-formed array of hashes unchanged (stringifying keys)' do
      expect(Hyrax::CompoundNormalization.normalize_compound([{ given_name: 'Ada' }]))
        .to eq([{ 'given_name' => 'Ada' }])
    end

    it 'returns nil unchanged' do
      expect(Hyrax::CompoundNormalization.normalize_compound(nil)).to be_nil
    end

    it 'wraps a single hash in an array' do
      expect(Hyrax::CompoundNormalization.normalize_compound({ 'given_name' => 'Ada' }))
        .to eq([{ 'given_name' => 'Ada' }])
    end
  end

  describe 'round-trip through the class constructor' do
    it 'normalizes splayed compound input passed to .new' do
      resource = resource_class.new(contributors: [[:given_name, 'Ada']])
      expect(resource.contributors).to eq([{ 'given_name' => 'Ada' }])
    end

    it 'normalizes well-formed compound input passed to .new' do
      resource = resource_class.new(contributors: [{ 'given_name' => 'Grace' }])
      expect(resource.contributors).to eq([{ 'given_name' => 'Grace' }])
    end
  end
end
