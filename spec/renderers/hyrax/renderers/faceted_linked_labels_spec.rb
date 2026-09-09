# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'controlled vocabulary labels in linking renderers' do
  let(:values)  { ['local_auth_123'] }
  let(:options) { { labels: { 'local_auth_123' => 'Opaque Term' } } }

  describe Hyrax::Renderers::FacetedAttributeRenderer do
    subject(:renderer) { described_class.new(:resource_type, values, options) }

    it 'shows the label as the link text' do
      expect(renderer.render).to include('Opaque Term')
    end

    it 'still searches on the stored id' do
      expect(renderer.render).to include('local_auth_123')
    end

    context 'with no labels' do
      let(:options) { {} }

      it 'renders the id as before' do
        expect(renderer.render).to include('local_auth_123')
      end
    end
  end

  describe Hyrax::Renderers::LinkedAttributeRenderer do
    subject(:renderer) { described_class.new(:resource_type, values, options) }

    it 'shows the label as the link text' do
      expect(renderer.render).to include('Opaque Term')
    end

    it 'still searches on the stored id' do
      expect(renderer.render).to include('local_auth_123')
    end
  end
end
