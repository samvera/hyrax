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

    context 'when type is not recognized' do
      let(:config) { { 'type' => 'custom' } }

      it 'raises an ArgumentError' do
        expect { attribute_definition.type }.to raise_error(ArgumentError, 'Unrecognized type: custom')
      end
    end

    context 'when the type names a nested Hyrax resource class (short form)' do
      # In a YAML schema, `type: redirect` resolves to `Hyrax::Redirect`,
      # so adopters can declare nested-resource attributes without
      # registering anything in the Valkyrie::Types namespace.
      let(:config) { { 'type' => 'redirect', 'multiple' => true } }

      it 'wraps the nested resource class in a typed array constructor' do
        expect(attribute_definition.type).to be_a(Dry::Types::Constructor)
        expect(attribute_definition.type.member).to eq(Hyrax::Redirect)
      end
    end

    context 'when a nested Hyrax resource type is declared with multiple: false' do
      # Single-value nested resources are not supported because the schema
      # loader's #type would return the bare class rather than a Dry::Types::Type,
      # producing a downstream shape inconsistency. The loader rejects this
      # configuration explicitly.
      let(:config) { { 'type' => 'redirect', 'multiple' => false } }

      it 'raises ArgumentError' do
        expect { attribute_definition.type }
          .to raise_error(ArgumentError, /nested resource members require `multiple: true`/)
      end
    end

    context 'when the type name has multiple words' do
      # The lookup uses String#classify (not capitalize), so multi-word
      # types like `access_control` resolve to `Hyrax::AccessControl`.
      it 'resolves a multi-word type via #classify' do
        expect(attribute_definition.send(:type_for, 'access_control')).to eq(Hyrax::AccessControl)
      end
    end

    context 'when the type is a fully-qualified class name' do
      # Adopters with their own namespace can write `type: MyApp::Citation`
      # in YAML and the loader will resolve it directly.
      it 'returns the named class' do
        expect(attribute_definition.send(:type_for, 'Hyrax::Redirect')).to eq(Hyrax::Redirect)
      end
    end

    context 'when the type name matches a class that is not a Valkyrie::Resource' do
      # ::StringIO is a real class but not a resource. Resolution must reject
      # it rather than silently use it as a nested-attribute type.
      let(:config) { { 'type' => 'string_io' } }

      it 'raises ArgumentError' do
        expect { attribute_definition.type }.to raise_error(ArgumentError, 'Unrecognized type: string_io')
      end
    end

    context 'when the type name singularizes via #classify (e.g. "data" -> "Datum")' do
      # String#classify singularizes, which can surprise. Confirm that an
      # unrecognized type still raises ArgumentError regardless of inflection
      # quirks — neither Hyrax::Datum, ::Datum, Valkyrie::Types::Datum, nor
      # any other resolution short-circuits the safety check.
      let(:config) { { 'type' => 'data' } }

      it 'raises ArgumentError' do
        expect { attribute_definition.type }.to raise_error(ArgumentError, 'Unrecognized type: data')
      end
    end
  end
end
