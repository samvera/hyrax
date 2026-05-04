# frozen_string_literal: true

RSpec.describe Hyrax::Redirect do
  describe '#initialize' do
    it 'accepts a path, canonical flag, and sequence' do
      r = described_class.new(path: '/handle/12345/678', canonical: true, sequence: 0)
      expect(r.path).to eq('/handle/12345/678')
      expect(r.canonical).to be true
      expect(r.sequence).to eq(0)
    end

    it 'defaults canonical to false' do
      r = described_class.new(path: '/foo')
      expect(r.canonical).to be false
    end

    it 'allows path and sequence to be nil (e.g. for the trailing blank row in the form view)' do
      r = described_class.new(path: nil)
      expect(r.path).to be_nil
      expect(r.sequence).to be_nil
    end
  end

  describe '.wrap' do
    it 'returns nil for nil input' do
      expect(described_class.wrap(nil)).to be_nil
    end

    it 'returns the same instance when input is already a presenter' do
      r = described_class.new(path: '/foo')
      expect(described_class.wrap(r)).to equal(r)
    end

    it 'builds a presenter from a string-keyed hash (JSONB shape)' do
      r = described_class.wrap('path' => '/foo', 'canonical' => true, 'sequence' => 2)
      expect(r).to have_attributes(path: '/foo', canonical: true, sequence: 2)
    end

    it 'builds a presenter from a symbol-keyed hash' do
      r = described_class.wrap(path: '/foo', canonical: true, sequence: 2)
      expect(r).to have_attributes(path: '/foo', canonical: true, sequence: 2)
    end

    it 'defaults canonical to false when omitted' do
      r = described_class.wrap('path' => '/foo')
      expect(r.canonical).to be false
    end

    it 'raises ArgumentError when input cannot be coerced to a hash' do
      expect { described_class.wrap(42) }.to raise_error(ArgumentError, /Hyrax::Redirect/)
    end
  end

  describe '#to_h and #as_json' do
    it 'returns a string-keyed hash matching the persisted shape' do
      r = described_class.new(path: '/foo', canonical: true, sequence: 1)
      expected = { 'path' => '/foo', 'canonical' => true, 'sequence' => 1 }
      expect(r.to_h).to eq(expected)
      expect(r.as_json).to eq(expected)
    end
  end

  describe '#==' do
    it 'compares equal on attribute values' do
      a = described_class.new(path: '/x', canonical: true, sequence: 0)
      b = described_class.new(path: '/x', canonical: true, sequence: 0)
      expect(a).to eq(b)
    end

    it 'differs when any attribute differs' do
      a = described_class.new(path: '/x')
      b = described_class.new(path: '/y')
      expect(a).not_to eq(b)
    end

    it 'is not equal to a Hash with the same shape (presenters and hashes are distinct types)' do
      r = described_class.new(path: '/x', canonical: false, sequence: nil)
      expect(r).not_to eq('path' => '/x', 'canonical' => false, 'sequence' => nil)
    end
  end
end
