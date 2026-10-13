# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'wings/converter_value_mapper'

RSpec.describe Wings::ConverterValueMapper do
  subject(:mapper) { described_class.for(value) }
  let(:value)      { 'a value' }

  describe '.for' do
    it 'returns a value mapper' do
      expect(described_class.for(value)).to be_a described_class
    end
  end

  describe '.result' do
    it 'returns the value by default' do
      expect(mapper.result).to eq value
    end

    context 'with a NestedResourceArray value'
    context 'with a NestedResource value'

    context 'with an array of plain hashes' do
      let(:value) { [:aliases, [{ 'path' => '/one', 'is_display_url' => true }, { path: '/two' }]] }

      it 'converts each hash to one JSON string' do
        expect(mapper.result)
          .to eq [:aliases, ['{"path":"/one","is_display_url":true}', '{"path":"/two"}']]
      end
    end

    context 'with a hash that names an internal resource' do
      let(:value) { [:nested, { internal_resource: 'Hyrax::Permission' }] }

      it 'leaves the hash unchanged' do
        expect(mapper.result).to eq value
      end
    end
  end
end
