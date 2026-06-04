# frozen_string_literal: true

RSpec.describe Hyrax::CompoundSubfieldLabeler do
  describe '.label_for' do
    it 'returns the value unchanged for a non-controlled sub-field' do
      spec = { type: 'string', authority: nil, values: nil }
      expect(described_class.label_for(spec, 'plain text')).to eq('plain text')
    end

    it 'returns the value unchanged when spec is nil' do
      expect(described_class.label_for(nil, 'whatever')).to eq('whatever')
    end

    it 'returns blank values unchanged' do
      spec = { type: 'controlled', authority: 'x', values: nil }
      expect(described_class.label_for(spec, '')).to eq('')
    end

    context 'with an inline values list' do
      let(:spec) { { type: 'controlled', authority: nil, values: [%w[Author author], %w[Editor ed]] } }

      it 'translates the stored id to its label' do
        expect(described_class.label_for(spec, 'ed')).to eq('Editor')
      end

      it 'falls back to the id when no matching option exists' do
        expect(described_class.label_for(spec, 'unknown')).to eq('unknown')
      end
    end

    context 'with a QA authority' do
      let(:spec) { { type: 'controlled', authority: 'rights_statements', values: nil } }
      let(:service) { instance_double(Hyrax::TolerantSelectService) }

      before do
        allow(Hyrax::TolerantSelectService).to receive(:new).with('rights_statements').and_return(service)
      end

      it 'translates the stored id to the authority term' do
        allow(service).to receive(:label).and_return('In Copyright')
        expect(described_class.label_for(spec, 'http://rightsstatements.org/vocab/InC/1.0/')).to eq('In Copyright')
      end

      it 'falls back to the id on lookup error' do
        allow(service).to receive(:label).and_raise(StandardError)
        expect(described_class.label_for(spec, 'http://example.org/x')).to eq('http://example.org/x')
      end
    end
  end
end
