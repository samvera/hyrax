# frozen_string_literal: true

RSpec.describe Hyrax::Redirect do
  describe '#initialize' do
    it 'accepts a path and is_display_url flag' do
      r = described_class.new(path: '/handle/12345/678', is_display_url: true)
      expect(r.path).to eq('/handle/12345/678')
      expect(r.is_display_url).to be true
    end

    it 'defaults is_display_url to false' do
      r = described_class.new(path: '/foo')
      expect(r.is_display_url).to be false
    end

    it 'allows path to be nil (e.g. for the trailing blank row in the form view)' do
      r = described_class.new(path: nil)
      expect(r.path).to be_nil
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
      r = described_class.wrap('path' => '/foo', 'is_display_url' => true)
      expect(r).to have_attributes(path: '/foo', is_display_url: true)
    end

    it 'builds a presenter from a symbol-keyed hash' do
      r = described_class.wrap(path: '/foo', is_display_url: true)
      expect(r).to have_attributes(path: '/foo', is_display_url: true)
    end

    it 'defaults is_display_url to false when omitted' do
      r = described_class.wrap('path' => '/foo')
      expect(r.is_display_url).to be false
    end

    it 'raises ArgumentError when input cannot be coerced to a hash' do
      expect { described_class.wrap(42) }.to raise_error(ArgumentError, /Hyrax::Redirect/)
    end
  end

  describe '#to_h and #as_json' do
    it 'returns a string-keyed hash matching the persisted shape' do
      r = described_class.new(path: '/foo', is_display_url: true)
      expected = { 'path' => '/foo', 'is_display_url' => true }
      expect(r.to_h).to eq(expected)
      expect(r.as_json).to eq(expected)
    end
  end

  describe '#==' do
    it 'compares equal on attribute values' do
      a = described_class.new(path: '/x', is_display_url: true)
      b = described_class.new(path: '/x', is_display_url: true)
      expect(a).to eq(b)
    end

    it 'differs when any attribute differs' do
      a = described_class.new(path: '/x')
      b = described_class.new(path: '/y')
      expect(a).not_to eq(b)
    end

    it 'is not equal to a Hash with the same shape (presenters and hashes are distinct types)' do
      r = described_class.new(path: '/x', is_display_url: false)
      expect(r).not_to eq('path' => '/x', 'is_display_url' => false)
    end
  end
end
