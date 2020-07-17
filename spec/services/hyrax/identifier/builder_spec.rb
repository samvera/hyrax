# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Identifier::Builder do
  subject(:builder) { described_class.new }

  it_behaves_like 'a Hyrax::Identifier::Builder'

  describe '#prefix' do
    it 'has a default prefix' do
      expect(builder.prefix).not_to be_empty
    end

    it 'accepts a prefix' do
      prefix = 'my_pfx'
      builder = described_class.new(prefix: prefix)
      expect(builder.prefix).to eq prefix
    end
  end

  describe '#build' do
    it 'uses the prefix' do
      expect(builder.build(hint: 'blah')).to start_with "#{builder.prefix}/"
    end

    context 'with a custom prefix' do
      subject(:builder) { described_class.new(prefix: prefix) }
      let(:prefix)      { 'fake_prefix' }

      it 'uses the prefix' do
        expect(builder.build(hint: 'blah')).to start_with "#{prefix}/"
      end
    end

    it 'raises an error with no hint' do
      expect { builder.build }.to raise_error ArgumentError
    end

    it 'uses the hint exactly, cast to uppercase' do
      expect(builder.build(hint: 'moomin')).to eq 'pfx/moomin'
    end
  end
end
