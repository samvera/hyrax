# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::M3SchemaLoader do
  subject(:schema_loader) { described_class.new }
  let(:profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }
  let(:schema) do
    Hyrax::FlexibleSchema.create(
      profile: profile
    )
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:find_by).and_return(schema)
  end

  describe '#attributes_for' do
    it 'provides an attributes hash' do
      expect(schema_loader.attributes_for(schema: Monograph.to_s))
        .to include(title: Valkyrie::Types::Array.of(Valkyrie::Types::String),
                    depositor: Valkyrie::Types::String)
    end

    it 'provides access to attribute metadata' do
      expect(schema_loader.attributes_for(schema: Monograph.to_s)[:title].meta)
        .to include({ "type" => "string",
                      "form" => { "multiple" => true, "primary" => true, "required" => true },
                      "index_keys" => ["title_sim", "title_tesim"],
                      "multiple" => true,
                      "predicate" => "http://purl.org/dc/terms/title" })
    end

    context 'with generated resource' do
      let(:sample_attribute) do
        YAML.safe_load(<<-YAML)
          properties:
            sample_attribute:
              available_on:
                class:
                - Monograph
              cardinality:
                minimum: 0
                maximum: 1
              multi_value: false
              controlled_values:
                format: http://www.w3.org/2001/XMLSchema#string
                sources:
                - 'null'
              display_label:
                default: Sample Attribute
              property_uri: http://hyrax-example.com/sample_attribute
              range: http://www.w3.org/2001/XMLSchema#string
              sample_values:
              - Example Sample Attribute
        YAML
      end
      let(:schema) do
        Hyrax::FlexibleSchema.create(
          profile: profile.deep_merge(sample_attribute)
        )
      end

      it 'provides an attributes hash' do
        expect(schema_loader.attributes_for(schema: Monograph.to_s))
          .to include(sample_attribute: Valkyrie::Types::Array.of(Valkyrie::Types::String))
      end
    end

    it 'provides a default schema for an undefined schema' do
      expect(schema_loader.attributes_for(schema: :NOT_A_SCHEMA))
        .to include(title: Valkyrie::Types::Array.of(Valkyrie::Types::String))
    end
  end

  describe '#index_rules_for' do
    it 'provides index configuration' do
      expect(schema_loader.index_rules_for(schema: Monograph.to_s)).to include(title_sim: :title, title_tesim: :title)
    end
  end

  describe '#form_definitions_for' do
    it 'provides form configuration' do
      expect(schema_loader.form_definitions_for(schema: Monograph.to_s))
        .to eq(title: { required: true, primary: true, multiple: true })
    end
  end

  describe '#view_definitions_for' do
    context 'when schema has attributes without view options' do
      it 'returns display labels and admin flag' do
        expect(schema_loader.view_definitions_for(schema: Monograph.to_s))
          .to eq({
                   creator: { "admin_only" => false, "display_label" => { "default" => "Creator" } },
                   date_modified: { "admin_only" => nil, "display_label" => { "default" => "blacklight.search.fields.show.date_modified_dtsi" } },
                   date_uploaded: { "admin_only" => nil, "display_label" => { "default" => "blacklight.search.fields.show.date_uploaded_dtsi" } },
                   depositor: { "admin_only" => false, "display_label" => { "default" => "Depositor" } },
                   title: { "admin_only" => false, "display_label" => { "default" => "blacklight.search.fields.show.title_tesim" } }
                 })
      end
    end

    context 'when schema has attributes with view options' do
      let(:profile_with_view) do
        modified_profile = profile.dup
        modified_profile['properties']['title']['view'] = {
          'label' => { 'en' => 'Title', 'es' => 'Título' },
          'html_dl' => true
        }
        modified_profile['properties']['description'] = {
          'available_on' => {
            'class' => ['Monograph']
          },
          'view' => {
            'label' => { 'en' => 'Description' },
            'display' => true
          },
          'cardinality' => { 'minimum' => 0 },
          'multi_value' => true,
          'property_uri' => 'http://purl.org/dc/terms/description',
          'range' => 'http://www.w3.org/2001/XMLSchema#string'
        }
        modified_profile
      end
      let(:schema_with_view) do
        Hyrax::FlexibleSchema.create(
          profile: profile_with_view
        )
      end

      before do
        allow(Hyrax::FlexibleSchema).to receive(:find_by).and_return(schema_with_view)
      end

      it 'returns hash with view definitions for attributes that have view options' do
        result = schema_loader.view_definitions_for(schema: Monograph.to_s)
        expect(result).to include(
          date_modified: { "admin_only" => nil, "display_label" => { "default" => "blacklight.search.fields.show.date_modified_dtsi" } },
          date_uploaded: { "admin_only" => nil, "display_label" => { "default" => "blacklight.search.fields.show.date_uploaded_dtsi" } },
          depositor: { "admin_only" => false, "display_label" => { "default" => "Depositor" } },
          description: { "admin_only" => nil, "display" => true, "display_label" => {} },
          title: { "admin_only" => false, "display_label" => { "default" => "blacklight.search.fields.show.title_tesim" }, "html_dl" => true }
        )
      end
    end

    context 'with context filtering' do
      let(:profile_with_context) do
        modified_profile = profile.dup
        modified_profile['properties']['title']['view'] = { 'label' => { 'en' => 'Title' } }
        modified_profile['properties']['contextual_field'] = {
          'available_on' => {
            'class' => ['Monograph'],
            'context' => 'flexible_context'
          },
          'view' => { 'label' => { 'en' => 'Contextual Field' } },
          'cardinality' => { 'minimum' => 0 },
          'multi_value' => true,
          'property_uri' => 'http://example.org/contextual_field',
          'range' => 'http://www.w3.org/2001/XMLSchema#string'
        }
        modified_profile
      end
      let(:schema_with_context) do
        Hyrax::FlexibleSchema.create(
          profile: profile_with_context
        )
      end

      before do
        allow(Hyrax::FlexibleSchema).to receive(:find_by).and_return(schema_with_context)
      end

      context 'when no context is provided' do
        it 'excludes fields with context requirements' do
          result = schema_loader.view_definitions_for(schema: Monograph.to_s, contexts: nil)
          expect(result).to include(title: { admin_only: false, display_label: { default: "blacklight.search.fields.show.title_tesim" } })
          expect(result).not_to have_key(:contextual_field)
        end
      end

      context 'when matching context is provided' do
        it 'includes fields matching the context' do
          result = schema_loader.view_definitions_for(schema: Monograph.to_s, contexts: 'flexible_context')
          expect(result).to include(
            contextual_field: { "admin_only" => nil, "display_label" => {} },
            date_modified: { "admin_only" => nil, "display_label" => { "default" => "blacklight.search.fields.show.date_modified_dtsi" } },
            date_uploaded: { "admin_only" => nil, "display_label" => { "default" => "blacklight.search.fields.show.date_uploaded_dtsi" } },
            depositor: { "admin_only" => false, "display_label" => { "default" => "Depositor" } },
            title: { "admin_only" => false, "display_label" => { "default" => "blacklight.search.fields.show.title_tesim" } }
          )
        end
      end

      context 'when non-matching context is provided' do
        it 'excludes fields with different context requirements' do
          result = schema_loader.view_definitions_for(schema: Monograph.to_s, contexts: 'other_context')
          expect(result).to include(title: { admin_only: false, display_label: { default: "blacklight.search.fields.show.title_tesim" } })
          expect(result).not_to have_key(:contextual_field)
        end
      end
    end

    context 'when database is unavailable' do
      before do
        allow(Hyrax::FlexibleSchema).to receive(:find_by).and_raise(ActiveRecord::StatementInvalid, "Database error")
      end

      it 'returns empty hash when database query fails' do
        expect(schema_loader.view_definitions_for(schema: Monograph.to_s)).to eq({})
      end
    end

    context 'with version parameter' do
      it 'passes version to schema lookup' do
        expect(Hyrax::FlexibleSchema).to receive(:find_by).with(id: 2)
        schema_loader.view_definitions_for(schema: Monograph.to_s, version: 2)
      end
    end
  end
end
