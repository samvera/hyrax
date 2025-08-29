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
end
