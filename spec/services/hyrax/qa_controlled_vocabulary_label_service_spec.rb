# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::QaControlledVocabularyLabelService do
  subject(:service) { described_class.new }

  # `Qa::Authorities::Local#all` normalizes a file-based authority's `term:` to
  # `label:`, while a table-based one emits `label:` natively. Both shapes are
  # exercised, since the resolver reads whichever is present.
  let(:label_keyed_terms) do
    [HashWithIndifferentAccess.new(id: 'http://example.org/by', label: 'Attribution', active: true),
     HashWithIndifferentAccess.new(id: 'http://example.org/nc', label: 'NonCommercial', active: false)]
  end

  let(:term_keyed_terms) do
    [HashWithIndifferentAccess.new(id: 'Article', term: 'Article'),
     HashWithIndifferentAccess.new(id: 'local_auth_123', term: 'Opaque Term')]
  end

  let(:licenses)       { FakeAuthority.new(label_keyed_terms) }
  let(:resource_types) { FakeAuthority.new(term_keyed_terms) }

  # Rails.cache is process-wide and outlives an example, so a map built by one
  # would otherwise answer for the next.
  around do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original
  end

  before do
    allow(Qa::Authorities::Local).to receive(:subauthorities).and_return(['licenses', 'resource_types'])
    allow(Qa::Authorities::Local).to receive(:subauthority_for).with('licenses').and_return(licenses)
    allow(Qa::Authorities::Local).to receive(:subauthority_for).with('resource_types').and_return(resource_types)
  end

  describe '#resolvable?' do
    it 'is true for a local authority' do
      expect(service.resolvable?('licenses')).to be true
    end

    it 'is false for a remote authority, which would cost a request per value' do
      expect(service.resolvable?('geonames')).to be false
    end

    it 'is false for the free-text sentinel and for blanks' do
      expect(service.resolvable?('null')).to be false
      expect(service.resolvable?('')).to be false
      expect(service.resolvable?(nil)).to be false
    end

    it 'tolerates a surrounding whitespace in a profile source' do
      expect(service.resolvable?(' licenses ')).to be true
    end
  end

  describe '#labels_for' do
    it 'resolves a label-keyed authority' do
      expect(service.labels_for('licenses', ['http://example.org/by'])).to eq ['Attribution']
    end

    it 'resolves a term-keyed authority' do
      expect(service.labels_for('resource_types', ['local_auth_123'])).to eq ['Opaque Term']
    end

    it 'keeps one entry per value, in order, for a mix of known and unknown ids' do
      expect(service.labels_for('resource_types', ['local_auth_123', 'unmapped', 'Article']))
        .to eq ['Opaque Term', 'unmapped', 'Article']
    end

    it 'wraps a single value' do
      expect(service.labels_for('resource_types', 'local_auth_123')).to eq ['Opaque Term']
    end

    it 'returns an empty array for no values' do
      expect(service.labels_for('licenses', nil)).to eq []
    end

    it 'returns the values unchanged for an authority it cannot resolve' do
      expect(service.labels_for('geonames', ['anything'])).to eq ['anything']
    end

    # An object may hold a term deactivated after it was deposited; it should
    # still display its label rather than a bare id.
    it 'resolves an inactive term' do
      expect(service.labels_for('licenses', ['http://example.org/nc'])).to eq ['NonCommercial']
    end
  end

  describe 'failure handling' do
    context 'when the application has no config/authorities at all' do
      before do
        allow(Qa::Authorities::Local).to receive(:subauthorities).and_raise(StandardError, 'no config directory')
      end

      it 'reports nothing resolvable rather than raising' do
        expect(service.resolvable?('licenses')).to be false
      end

      it 'returns the values unchanged' do
        expect(service.labels_for('licenses', ['http://example.org/by'])).to eq ['http://example.org/by']
      end
    end

    context 'when an authority raises while listing its terms' do
      before { allow(licenses).to receive(:all).and_raise(StandardError, 'backend down') }

      it 'returns the values unchanged rather than failing an indexing run' do
        expect(service.labels_for('licenses', ['http://example.org/by'])).to eq ['http://example.org/by']
      end
    end
  end

  describe 'memoization' do
    it 'builds an authority label map once, however many times it is asked' do
      3.times { service.labels_for('licenses', ['http://example.org/by']) }

      expect(Qa::Authorities::Local).to have_received(:subauthority_for).with('licenses').once
    end

    it 'keeps separate maps per authority' do
      expect(service.labels_for('licenses', ['http://example.org/by'])).to eq ['Attribution']
      expect(service.labels_for('resource_types', ['local_auth_123'])).to eq ['Opaque Term']
    end
  end
end
