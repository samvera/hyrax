# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::SimpleSchemaLoader do
  subject(:schema_loader) { described_class.new }

  describe '#attributes_for' do
    it 'provides an attributes hash' do
      expect(schema_loader.attributes_for(schema: :core_metadata))
        .to include(title:     Valkyrie::Types::Array.of(Valkyrie::Types::String),
                    depositor: Valkyrie::Types::String)
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
        .to eq(title: { required: true, primary: true, multiple: false })
    end
  end
end
