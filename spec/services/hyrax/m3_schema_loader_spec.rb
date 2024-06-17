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
    allow(Hyrax::FlexibleSchema).to receive(:find).and_return(schema)
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
      let(:sample_attribute) { YAML.safe_load_file(Rails.root.join('config', 'metadata_profiles', 'sample_attribute.yaml')) }
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

    it 'raises an error for an undefined schema' do
      expect { schema_loader.attributes_for(schema: :NOT_A_SCHEMA) }
        .to raise_error described_class::UndefinedSchemaError
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
