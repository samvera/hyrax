# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::Renderers::AttributeRenderer, 'controlled vocabulary labels' do
  subject(:renderer) { described_class.new(:resource_type, values, options) }

  let(:values) { ['local_auth_123'] }

  describe 'with a labels hash' do
    let(:options) { { labels: { 'local_auth_123' => 'Opaque Term' } } }

    it 'renders the label in place of the id' do
      expect(renderer.render).to include('Opaque Term')
      expect(renderer.render).not_to include('>local_auth_123<')
    end
  end

  describe 'with a value the hash does not cover' do
    let(:values)  { ['local_auth_123', 'unmapped'] }
    let(:options) { { labels: { 'local_auth_123' => 'Opaque Term' } } }

    it 'renders the label for the covered value and the id for the other' do
      expect(renderer.render).to include('Opaque Term', 'unmapped')
    end
  end

  describe 'with a label identical to its value' do
    let(:options) { { labels: { 'local_auth_123' => 'local_auth_123' } } }

    it 'renders the value once, without a redundant substitution' do
      expect(renderer.render).to include('local_auth_123')
    end
  end

  describe 'with a linkable URI value' do
    let(:values)  { ['http://example.org/terms/image'] }
    let(:options) { { labels: { 'http://example.org/terms/image' => 'Image' } } }

    it 'links the id and displays the label' do
      expect(renderer.render).to include('<a href="http://example.org/terms/image"', '>Image</a>')
    end
  end

  describe 'with a non-linkable value carrying HTML in its label' do
    let(:options) { { labels: { 'local_auth_123' => '<script>alert(1)</script>' } } }

    it 'escapes the label' do
      expect(renderer.render).to include('&lt;script&gt;')
      expect(renderer.render).not_to include('<script>')
    end
  end

  # These shapes cannot arise from Hyrax's own presenter, which always builds a
  # hash; they come from downstream callers, since options is public and free-form.
  describe 'with a labels option that is not a hash' do
    [true, false, 'Opaque Term', ['Opaque Term'], 42, nil].each do |bad|
      context "when labels is #{bad.inspect}" do
        let(:options) { { labels: bad } }

        it 'renders the values unchanged rather than raising' do
          expect { renderer.render }.not_to raise_error
          expect(renderer.render).to include('local_auth_123')
        end
      end
    end
  end

  describe 'with no labels option at all' do
    let(:options) { {} }

    it 'renders exactly as it did before labels existed' do
      expect(renderer.render).to eq(described_class.new(:resource_type, values, {}).render)
      expect(renderer.render).to include('local_auth_123')
    end
  end
end
