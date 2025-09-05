# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::SimpleSchemaLoader do
  subject(:schema_loader) { described_class.new }

  describe '#attributes_for' do
    it 'provides an attributes hash' do
      expect(schema_loader.attributes_for(schema: :core_metadata))
        .to include(title: Valkyrie::Types::Array.of(Valkyrie::Types::String),
                    depositor: Valkyrie::Types::String)
    end

    it 'provides access to attribute metadata' do
      expect(schema_loader.attributes_for(schema: :core_metadata)[:title].meta)
        .to include({ "type" => "string",
                      "form" => { "multiple" => true, "primary" => true, "required" => true },
                      "index_keys" => ["title_sim", "title_tesim"],
                      "multiple" => true,
                      "predicate" => "http://purl.org/dc/terms/title" })
    end

    context 'with generated resource' do
      it 'provides an attributes hash' do
        expect(schema_loader.attributes_for(schema: :sample_metadata))
          .to include(sample_attribute: Valkyrie::Types::Array.of(Valkyrie::Types::String))
      end
    end

    it 'raises an error for an undefined schema' do
      expect { schema_loader.attributes_for(schema: :NOT_A_SCHEMA) }
        .to raise_error described_class::UndefinedSchemaError
    end
  end

  describe '#index_rules_for' do
    it 'provides index configuration' do
      expect(schema_loader.index_rules_for(schema: :core_metadata)).to include(title_sim: :title, title_tesim: :title)
    end
  end

  describe '#form_definitions_for' do
    it 'provides form configuration' do
      expect(schema_loader.form_definitions_for(schema: :core_metadata))
        .to eq(title: { required: true, primary: true, multiple: true })
    end
  end

  describe '#view_definitions_for' do
    context 'when schema has no attributes with view options' do
      it 'returns empty hash' do
        # The SimpleSchemaLoader expects objects with a `meta` method like property objects
        mock_property = double('Property', name: :title, meta: {})
        schema_with_no_view = [mock_property]
        result = schema_loader.view_definitions_for(schema: schema_with_no_view)
        expect(result).to eq({})
      end
    end

    context 'when passed schema object directly' do
      let(:mock_property) do
        double('Property',
               name: :test_attribute,
               meta: { 'view' => { 'label' => { 'en' => 'Test Label' } } })
      end
      let(:mock_property_no_view) do
        double('Property',
               name: :no_view_attribute,
               meta: {})
      end
      let(:schema_with_view) { [mock_property, mock_property_no_view] }

      it 'processes schema objects with view metadata' do
        result = schema_loader.view_definitions_for(schema: schema_with_view)
        expect(result).to eq(
          'test_attribute' => { 'label' => { 'en' => 'Test Label' } }
        )
      end

      it 'excludes properties without view metadata' do
        result = schema_loader.view_definitions_for(schema: schema_with_view)
        expect(result).not_to have_key('no_view_attribute')
      end

      it 'handles properties with nil view metadata' do
        mock_property_nil = double('Property', name: :nil_view, meta: { 'view' => nil })
        schema_with_nil = [mock_property_nil]
        result = schema_loader.view_definitions_for(schema: schema_with_nil)
        expect(result).to eq({})
      end
    end

    context 'when schema has attributes with view options' do
      let(:mock_property_with_view) do
        double('Property',
               name: :sample_attribute,
               meta: {
                 'view' => {
                   'label' => { 'en' => 'Sample Attribute', 'es' => 'Atributo de muestra' },
                   'display' => true
                 }
               })
      end
      let(:mock_property_no_view) do
        double('Property',
               name: :sample_without_view,
               meta: {})
      end
      let(:schema_with_mixed_view) { [mock_property_with_view, mock_property_no_view] }

      it 'returns hash with view definitions for attributes that have view options' do
        result = schema_loader.view_definitions_for(schema: schema_with_mixed_view)
        expect(result).to include(
          'sample_attribute' => {
            'label' => { 'en' => 'Sample Attribute', 'es' => 'Atributo de muestra' },
            'display' => true
          }
        )
      end

      it 'excludes attributes without view options' do
        result = schema_loader.view_definitions_for(schema: schema_with_mixed_view)
        expect(result).not_to have_key('sample_without_view')
      end
    end

    context 'with version and contexts parameters' do
      it 'ignores version and contexts parameters as documented' do
        mock_property = double('Property', name: :title, meta: {})
        schema_objects = [mock_property]
        expect do
          schema_loader.view_definitions_for(schema: schema_objects, version: 2, contexts: ['test'])
        end.not_to raise_error
      end
    end
  end

  describe '#permissive_schema_for_valkrie_adapter' do
    let(:permissive_schema) { schema_loader.permissive_schema_for_valkrie_adapter }

    it 'provides the expected hash' do
      expect(permissive_schema.size).to eq(66)
      expect(permissive_schema.values.all? { |v| v.is_a? RDF::URI }).to be_truthy
      expect(permissive_schema.values.all? { |v| v.value.present? }).to be_truthy
      expect(permissive_schema[:sample_attribute].value).to eq("http://hyrax-example.com/sample_attribute")
    end
  end
end
