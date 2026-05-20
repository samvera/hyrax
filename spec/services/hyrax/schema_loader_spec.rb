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

  describe '#admin_only?' do
    context 'when set as a top-level key' do
      let(:config) { { 'type' => 'string', 'admin_only' => true } }
      it { expect(attribute_definition.admin_only?).to be true }
    end

    context 'when set in the indexing array' do
      let(:config) { { 'type' => 'string', 'indexing' => ['stored_searchable', 'admin_only'] } }
      it { expect(attribute_definition.admin_only?).to be true }
    end

    context 'when neither is set' do
      it { expect(attribute_definition.admin_only?).to be_falsey }
    end
  end

  describe '#editor_only?' do
    context 'when set as a top-level key' do
      let(:config) { { 'type' => 'string', 'editor_only' => true } }
      it { expect(attribute_definition.editor_only?).to be true }
    end

    context 'when set in the indexing array' do
      let(:config) { { 'type' => 'string', 'indexing' => ['stored_searchable', 'editor_only'] } }
      it { expect(attribute_definition.editor_only?).to be true }
    end

    context 'when neither is set' do
      it { expect(attribute_definition.editor_only?).to be_falsey }
    end
  end

  describe '#index_keys' do
    context 'when indexing array contains visibility flags' do
      let(:config) { { 'type' => 'string', 'indexing' => ['title_tesim', 'stored_searchable', 'facetable', 'admin_only', 'editor_only'] } }

      it 'filters out facetable, stored_searchable, admin_only, and editor_only' do
        expect(attribute_definition.index_keys).to eq([:title_tesim])
      end
    end
  end

  describe '#view_options' do
    let(:config) { { 'type' => 'string', 'admin_only' => true, 'editor_only' => true, 'view' => { 'html_dl' => true } } }

    it 'includes admin_only and editor_only flags' do
      expect(attribute_definition.view_options[:admin_only]).to be true
      expect(attribute_definition.view_options[:editor_only]).to be true
      expect(attribute_definition.view_options[:html_dl]).to be true
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

      it 'returns a string-typed constructor that coerces blanks to nil' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        # Real strings pass through.
        expect(attribute_definition.type.call('hello')).to eq('hello')
        # Blank strings become nil, matching the multi-value branch's blank cleanup.
        expect(attribute_definition.type.call('')).to be_nil
        expect(attribute_definition.type.call('   ')).to be_nil
        # The dry-types Undefined placeholder is dropped.
        expect(attribute_definition.type.call(Dry::Types::Undefined)).to be_nil
      end
    end

    context 'when multiple is false and the underlying type is non-string' do
      let(:config) { { 'type' => 'date_time', 'multiple' => false } }

      it 'wraps the type but lets non-string values pass through unchanged' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        time = DateTime.new(2026, 1, 1)
        expect(attribute_definition.type.call(time)).to eq(time)
      end
    end

    context 'when type is id' do
      let(:config) { { 'type' => 'id' } }

      it 'returns a constructor that coerces input to a Valkyrie::ID' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        expect(attribute_definition.type.call('abc')).to eq(Valkyrie::ID.new('abc'))
      end
    end

    context 'when type is uri' do
      let(:config) { { 'type' => 'uri' } }

      it 'returns a constructor that coerces input to an RDF::URI' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        expect(attribute_definition.type.call('http://example.com')).to eq(RDF::URI('http://example.com'))
      end
    end

    context 'when type is date_time' do
      let(:config) { { 'type' => 'date_time' } }

      it 'returns a constructor wrapping the Valkyrie DateTime type' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        time = DateTime.new(2026, 1, 1)
        expect(attribute_definition.type.call(time)).to eq(time)
      end
    end

    context 'when type is hash' do
      # The `hash` shortcut lets a YAML schema declare a nested-attribute
      # property whose entries are plain hashes (e.g. `redirects` with
      # `path` and `display_url` sub-fields). Persisted as JSONB without
      # a nested Valkyrie::Resource schema in between, so round-trips
      # don't strip sub-fields. See documentation/redirects.md.
      let(:config) { { 'type' => 'hash', 'multiple' => true } }

      it 'returns an array-of-hash typed constructor that round-trips hash entries' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        expect(attribute_definition.type.to_s).to include('Array')
        # End-to-end: an array of hashes coerces to itself, preserving sub-keys.
        input = [{ 'path' => '/foo', 'display_url' => true }]
        expect(attribute_definition.type.call(input)).to eq(input)
      end
    end

    context 'when type is hash with multiple: false' do
      let(:config) { { 'type' => 'hash', 'multiple' => false } }

      it 'returns a constructor wrapping Dry::Types["hash"] that passes hashes through' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        expect(attribute_definition.type.type).to eq(Dry::Types['hash'])
        input = { 'path' => '/foo', 'display_url' => true }
        expect(attribute_definition.type.call(input)).to eq(input)
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
