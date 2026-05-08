# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::SchemaLoader do
  subject(:schema_loader) { described_class.new }

  describe '#definitions' do
    it 'raises NotImplementedError' do
      expect { schema_loader.send(:definitions, :some_schema, 1, nil) }
        .to raise_error(NotImplementedError, 'Implement #definitions in a child class')
    end
  end
end

RSpec.describe Hyrax::SchemaLoader::AttributeDefinition do
  subject(:attribute_definition) { described_class.new(name, config) }

  let(:name) { 'title' }
  let(:config) do
    { 'type' => 'string',
      'form' => { 'multiple' => true, 'primary' => true, 'required' => true },
      'index_keys' => ['title_sim', 'title_tesim'],
      'multiple' => true,
      'predicate' => 'http://purl.org/dc/terms/title' }
  end

  describe '#form_options' do
    it 'returns form options as a symbolized hash' do
      expect(attribute_definition.form_options).to eq(multiple: true, primary: true, required: true)
    end

    context 'when form options are missing' do
      let(:config) { { 'type' => 'string' } }

      it 'returns an empty hash' do
        expect(attribute_definition.form_options).to eq({})
      end
    end
  end

  describe '#index_keys' do
    it 'returns index keys as symbols' do
      expect(attribute_definition.index_keys).to eq([:title_sim, :title_tesim])
    end

    context 'when index keys are missing' do
      let(:config) { { 'type' => 'string' } }

      it 'returns an empty array' do
        expect(attribute_definition.index_keys).to eq([])
      end
    end
  end

  describe '#type' do
    context 'when multiple is true' do
      it 'returns a Valkyrie array type' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        expect(attribute_definition.type.to_s).to include('Array')
        expect(attribute_definition.type.member).to eq(Valkyrie::Types::String)
      end
    end

    context 'when multiple is false' do
      let(:config) { { 'type' => 'string', 'multiple' => false } }

      it 'returns a Valkyrie string type' do
        expect(attribute_definition.type).to eq(Valkyrie::Types::String)
      end
    end

    context 'when type is id' do
      let(:config) { { 'type' => 'id' } }

      it 'returns a Valkyrie ID type' do
        expect(attribute_definition.type).to eq(Valkyrie::Types::ID)
      end
    end

    context 'when type is uri' do
      let(:config) { { 'type' => 'uri' } }

      it 'returns a Valkyrie URI type' do
        expect(attribute_definition.type).to eq(Valkyrie::Types::URI)
      end
    end

    context 'when type is date_time' do
      let(:config) { { 'type' => 'date_time' } }

      it 'returns a Valkyrie DateTime type' do
        expect(attribute_definition.type).to eq(Valkyrie::Types::DateTime)
      end
    end

    context 'when type is hash' do
      # The `hash` shortcut lets a YAML schema declare a nested-attribute
      # property whose entries are plain hashes (e.g. `redirects` with
      # `path`, `canonical`, `sequence` sub-fields). Persisted as JSONB
      # without a nested Valkyrie::Resource schema in between, so round-trips
      # don't strip sub-fields. See documentation/redirects.md.
      let(:config) { { 'type' => 'hash', 'multiple' => true } }

      it 'returns an array-of-hash typed constructor that round-trips hash entries' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        expect(attribute_definition.type.to_s).to include('Array')
        # End-to-end: an array of hashes coerces to itself, preserving sub-keys.
        input = [{ 'path' => '/foo', 'canonical' => true, 'sequence' => 0 }]
        expect(attribute_definition.type.call(input)).to eq(input)
      end
    end

    context 'when type is hash with multiple: false' do
      let(:config) { { 'type' => 'hash', 'multiple' => false } }

      it 'returns a bare Dry::Types["hash"]' do
        expect(attribute_definition.type).to eq(Dry::Types['hash'])
      end
    end

    context 'when type is not recognized' do
      let(:config) { { 'type' => 'custom' } }

      it 'raises an ArgumentError' do
        expect { attribute_definition.type }.to raise_error(ArgumentError, 'Unrecognized type: custom')
      end
    end

    context 'when the type name matches an unrelated Ruby class' do
      # ::StringIO is a real class but not a Valkyrie::Types::*. Resolution
      # must reject it rather than silently match it via #classify.
      let(:config) { { 'type' => 'string_io' } }

      it 'raises ArgumentError' do
        expect { attribute_definition.type }.to raise_error(ArgumentError, 'Unrecognized type: string_io')
      end
    end

    context 'when the type name singularizes via #classify (e.g. "data" -> "Datum")' do
      # String#classify singularizes, which can surprise. Confirm that an
      # unrecognized type still raises ArgumentError regardless of inflection
      # quirks.
      let(:config) { { 'type' => 'data' } }

      it 'raises ArgumentError' do
        expect { attribute_definition.type }.to raise_error(ArgumentError, 'Unrecognized type: data')
      end
    end
  end
end
