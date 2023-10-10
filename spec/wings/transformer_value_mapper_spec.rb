# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'wings/transformer_value_mapper'

RSpec.describe Wings::TransformerValueMapper, :active_fedora do
  subject(:mapper) { described_class.for(value) }
  let(:value)      { 'a value' }
  let(:uri)        { RDF::URI('http://example.com/moomin') }

  describe '.for' do
    it 'returns a value mapper' do
      expect(described_class.for(value)).to be_a described_class
    end
  end

  describe '.result' do
    it 'returns the value by default' do
      expect(mapper.result).to eq value
    end

    context 'with an ActiveTriples::RDFSource URI value' do
      let(:value) { ActiveTriples::Resource.new(uri) }

      it 'casts to the RDF term' do
        expect(mapper.result).to eq uri
      end
    end

    context 'with an ActiveTriples::RDFSource bnode value' do
      let(:value) { ActiveTriples::Resource.new(node) }
      let(:node)  { RDF::Node.new }

      it 'somehow manages to map the node?'
    end

    context 'with an ActiveTriples::Relation value' do
      let(:value)       { work.source }
      let(:work)        { GenericWork.new(source: cast_values) }
      let(:cast_values) { ['moomin', 1.125, :moomin, Time.now.utc, false, uri] }

      it 'casts internal values' do
        expect(mapper.result).to contain_exactly(*cast_values)
      end
    end

    context 'with a URI value'
    context 'with a blank node value'
    context 'with a boolean value'
    context 'with a date value'
    context 'with a numeric value'

    context 'with an enumerable value' do
      let(:value) { ['a value', 'another value'] }

      it 'maps single values' do
        expect(mapper.result).to contain_exactly(*value)
      end
    end
  end
end
