# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax do
  describe '.logger' do
    it 'is a Logger' do
      expect(described_class.logger).to respond_to :log
    end
  end

  describe '.schema_for' do
    let(:field) { double('Field', name: :title) }
    let(:non_flexible_klass) do
      klass = Class.new do
        def self.name
          'TestWork'
        end
      end
      schema_fields = [field]
      klass.define_singleton_method(:schema) { schema_fields }
      klass
    end

    it 'returns the schema for a non-flexible class without admin_set_id' do
      expect(described_class.schema_for(klass: non_flexible_klass)).to include(field)
    end

    it 'returns a schema that callers can map to property names (contract)' do
      schema = described_class.schema_for(klass: non_flexible_klass)
      expect(schema.map { |k| k.name.to_s }).to include('title')
    end

    it 'returns base schema when admin_set_id is nil' do
      expect(described_class.schema_for(klass: non_flexible_klass, admin_set_id: nil)).to include(field)
    end

    context 'when the admin set has contexts and the model is flexible' do
      let(:ctx_field)      { double('Field', name: :dimensions) }
      let(:flex_instance)  { double('instance', contexts: nil) }
      let(:flex_singleton) { double('singleton', schema: [field, ctx_field]) }
      let(:flex_klass) do
        klass = Class.new do
          def self.name
            'FlexWork'
          end
        end
        allow(klass).to receive(:flexible?).and_return(true)
        allow(klass).to receive(:new).with(contexts: ['special_context']).and_return(flex_instance)
        allow(flex_instance).to receive(:singleton_class).and_return(flex_singleton)
        klass
      end
      let(:admin_set) { double('AdminSet', contexts: ['special_context']) }

      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(true)
        allow(Hyrax.query_service).to receive(:find_by).with(id: 'set-1').and_return(admin_set)
      end

      it 'returns a schema that includes the context-specific field' do
        schema = described_class.schema_for(klass: flex_klass, admin_set_id: 'set-1')
        expect(schema).to include(ctx_field)
      end
    end

    context 'when the admin set is not found' do
      before do
        allow(Hyrax.query_service).to receive(:find_by).with(id: 'missing')
                                                       .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it 'falls back to the base schema without raising' do
        expect { described_class.schema_for(klass: non_flexible_klass, admin_set_id: 'missing') }.not_to raise_error
      end
    end

    context 'with a real Valkyrie resource class (Hyrax::Work)' do
      it 'returns a schema with keys/types (e.g. title)' do
        schema = described_class.schema_for(klass: Hyrax::Work)
        keys = schema.respond_to?(:keys) ? schema.keys : schema
        key_names = keys.map { |k| (k.respond_to?(:name) ? k.name : k).to_s.chomp('?').to_sym }
        expect(key_names).to include(:title)
      end
    end
  end

  describe '.deprecator' do
    it 'is a deprecator' do
      expect(described_class.deprecator).to respond_to(:warn)
    end

    it 'can take an argument' do
      default_deprecator = described_class.deprecator
      four_deprecator = described_class.deprecator(4)
      expect(default_deprecator.deprecation_horizon).to eq('6.0')
      expect(four_deprecator.deprecation_horizon).to eq('4.0')
    end
  end
end
