# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FlexibleCatalogConfigBuilder do
  subject(:builder) { described_class.new(config) }

  let(:config) do
    Blacklight::Configuration.new do |blacklight|
      blacklight.add_search_field('all_fields') { |field| field.solr_parameters = { qf: String.new('') } }
    end
  end
  let(:base_profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }
  let(:resource_type) do
    { 'available_on' => { 'class' => ['GenericWork'] },
      'controlled_values' => { 'format' => 'http://www.w3.org/2001/XMLSchema#string', 'sources' => ['resource_types'] },
      'display_label' => { 'default' => 'Resource Type' },
      'indexing' => %w[resource_type_sim resource_type_tesim stored_searchable facetable],
      'property_uri' => 'http://purl.org/dc/terms/type',
      'range' => 'http://www.w3.org/2001/XMLSchema#string' }
  end
  let(:profile) { base_profile.deep_merge('properties' => { 'resource_type' => resource_type }) }
  let(:label_service) do
    Class.new(Hyrax::ControlledVocabularyLabelService) do
      def resolvable?(source)
        source == 'resource_types'
      end
    end.new
  end

  before { allow(Hyrax.config).to receive(:controlled_vocabulary_label_service).and_return(label_service) }

  describe '#apply' do
    it 'builds the profile onto the config it was given and returns that config' do
      expect(builder.apply(profile, profile)).to be config
      expect(config.facet_fields).to include('resource_type_label_sim')
    end

    it 'applies the previous profile when there is no current one' do
      builder.apply(profile, nil)

      expect(config.facet_fields).to include('resource_type_label_sim')
    end

    it 'removes the fields of a property only an earlier revision declared' do
      config.add_facet_field('shelf_mark_sim')
      config.add_index_field('shelf_mark_tesim')

      builder.apply(profile, profile, earlier_properties: { 'shelf_mark' => { 'indexing' => %w[shelf_mark_sim shelf_mark_tesim] } })

      expect(config.facet_fields).not_to include('shelf_mark_sim')
      expect(config.index_fields).not_to include('shelf_mark_tesim')
    end

    it "removes the fields of a retired surrogate's target that no current property uses" do
      config.add_facet_field('shelf_mark_sim')
      config.add_index_field('shelf_mark_tesim')

      builder.apply(profile, profile, earlier_properties: { 'monograph_shelf_mark' => { 'names' => ['shelf_mark'], 'indexing' => %w[stored_searchable facetable editor_only] } })

      expect(config.facet_fields).not_to include('shelf_mark_sim')
      expect(config.index_fields).not_to include('shelf_mark_tesim')
    end

    it 'removes the fields of a target a current surrogate no longer stands in for' do
      config.add_facet_field('shelf_mark_sim')
      config.add_index_field('shelf_mark_tesim')
      surrogate = resource_type.merge('name' => 'call_number', 'indexing' => %w[stored_searchable facetable editor_only], 'controlled_values' => { 'sources' => ['null'] })
      retargeted = profile.deep_merge('properties' => { 'monograph_shelf_mark' => surrogate })

      builder.apply(retargeted, retargeted, earlier_properties: { 'monograph_shelf_mark' => { 'names' => %w[shelf_mark call_number], 'indexing' => %w[stored_searchable facetable editor_only] } })

      expect(config.facet_fields).not_to include('shelf_mark_sim')
      expect(config.index_fields).not_to include('shelf_mark_tesim')
    end

    it 'keeps the settings of a field an earlier property shared with a current one' do
      config.add_index_field('resource_type_tesim', label: 'Resource Type', helper_method: :an_application_helper)

      builder.apply(profile, profile, earlier_properties: { 'monograph_resource_type' => { 'indexing' => %w[resource_type_sim resource_type_tesim] } })

      expect(config.index_fields['resource_type_tesim'].helper_method).to eq :an_application_helper
    end
  end
end
