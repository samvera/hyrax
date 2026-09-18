# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::PresentsAttributes, 'controlled vocabulary labels' do
  subject(:presenter) { presenter_class.new(document) }

  let(:presenter_class) do
    Class.new do
      include Hyrax::PresentsAttributes

      attr_reader :solr_document

      def initialize(solr_document)
        @solr_document = solr_document
      end

      def resource_type
        Array(solr_document['resource_type_tesim'])
      end
    end
  end

  let(:document) { SolrDocument.new(fields) }

  context 'when the document carries indexed labels' do
    let(:fields) do
      { 'resource_type_tesim' => ['local_auth_123'],
        'resource_type_label_tesim' => ['Opaque Term'] }
    end

    it 'renders the label rather than the id' do
      expect(presenter.attribute_to_html(:resource_type)).to include('Opaque Term')
    end

    it 'passes the labels to the renderer keyed by value, alongside the values' do
      expect(Hyrax::Renderers::AttributeRenderer)
        .to receive(:new)
        .with(:resource_type, ['local_auth_123'], hash_including(labels: { 'local_auth_123' => 'Opaque Term' }))
        .and_call_original

      presenter.attribute_to_html(:resource_type)
    end
  end

  context 'when the id is a linkable URI' do
    let(:fields) do
      { 'resource_type_tesim' => ['http://example.org/terms/image'],
        'resource_type_label_tesim' => ['Image'] }
    end

    it 'links the label to the id' do
      expect(presenter.attribute_to_html(:resource_type))
        .to include('<a href="http://example.org/terms/image"', '>Image</a>')
    end
  end

  context 'when the values are sorted' do
    let(:fields) do
      { 'resource_type_tesim' => ['zebra_id', 'apple_id'],
        'resource_type_label_tesim' => ['Zebra Label', 'Apple Label'] }
    end

    it 'keeps each label with its own value rather than pairing by position' do
      html = presenter.attribute_to_html(:resource_type, sort: true)

      expect(html.index('Apple Label')).to be < html.index('Zebra Label')
    end
  end

  context 'when the label count does not match the value count' do
    let(:fields) do
      { 'resource_type_tesim' => ['a', 'b', 'c'],
        'resource_type_label_tesim' => ['Label A', 'Label C'] }
    end

    it 'falls back to the ids rather than pairing a value with another value label' do
      html = presenter.attribute_to_html(:resource_type)

      expect(html).to include('a', 'b', 'c')
      expect(html).not_to include('Label C')
    end
  end

  context 'when the property declares a custom index key' do
    let(:fields) do
      { 'resource_type_tesim' => ['local_auth_123'],
        'resource_type_label_ssim' => ['Opaque Term'] }
    end

    it 'reads the label companion the indexer wrote for that key' do
      expect(presenter.attribute_to_html(:resource_type)).to include('Opaque Term')
    end
  end

  context 'when a sibling property shares the label prefix' do
    let(:fields) do
      { 'resource_type_tesim' => ['local_auth_123'],
        'resource_type_label_note_tesim' => ['A different property'] }
    end

    it 'does not read the sibling property as this one\'s labels' do
      expect(presenter.attribute_to_html(:resource_type)).to include('local_auth_123')
      expect(presenter.attribute_to_html(:resource_type)).not_to include('A different property')
    end
  end

  context 'when a preferred label field is present but empty' do
    let(:fields) do
      { 'resource_type_tesim' => ['local_auth_123'],
        'resource_type_label_tesim' => [],
        'resource_type_label_ssim' => ['Opaque Term'] }
    end

    it 'falls through to a populated label field rather than giving up' do
      expect(presenter.attribute_to_html(:resource_type)).to include('Opaque Term')
    end
  end

  context 'when the work was indexed before the label fields existed' do
    let(:fields) { { 'resource_type_tesim' => ['local_auth_123'] } }

    it 'falls back to the id rather than rendering blank' do
      expect(presenter.attribute_to_html(:resource_type)).to include('local_auth_123')
    end
  end

  context 'when a value has no label indexed for it' do
    let(:fields) do
      { 'resource_type_tesim' => ['known_id', 'unknown_id'],
        'resource_type_label_tesim' => ['Known Label', 'unknown_id'] }
    end

    it 'shows the label for the resolved value and the id for the other' do
      html = presenter.attribute_to_html(:resource_type)

      expect(html).to include('Known Label', 'unknown_id')
    end
  end
end
