# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FlexibleCatalogBehavior, 'loading the profile while other requests hold the config', type: :controller do
  let(:base_profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }
  let(:resource_type) do
    YAML.safe_load(<<-YAML)
      available_on:
        class:
          - GenericWork
      controlled_values:
        format: http://www.w3.org/2001/XMLSchema#string
        sources:
          - resource_types
      display_label:
        default: Resource Type
      indexing:
        - resource_type_sim
        - resource_type_tesim
        - stored_searchable
        - facetable
      property_uri: http://purl.org/dc/terms/type
      range: http://www.w3.org/2001/XMLSchema#string
    YAML
  end
  let(:first_profile) { base_profile.deep_merge('properties' => { 'resource_type' => resource_type }) }
  let(:second_profile) do
    base_profile.deep_merge('properties' => { 'shelf_mark' => resource_type.merge('indexing' => %w[shelf_mark_tesim stored_searchable],
                                                                                    'controlled_values' => { 'sources' => ['null'] }) })
  end
  let(:schema) { ->(profile) { double('FlexibleSchema', profile:) } }
  let(:label_service) do
    Class.new(Hyrax::ControlledVocabularyLabelService) do
      def resolvable?(source)
        source == 'resource_types'
      end
    end.new
  end

  controller(ApplicationController) do
    include Blacklight::Configurable
    include Blacklight::SearchContext
    include Hyrax::FlexibleCatalogBehavior

    configure_blacklight do |config|
      config.add_search_field('all_fields') { |field| field.solr_parameters = { qf: String.new('') } }
    end
  end

  around do |example|
    klass = self.class.controller_class
    original = klass.blacklight_config.deep_copy
    example.run
    klass.blacklight_config = original
    klass.reset_flexible_baseline!
  end

  before do
    allow(Hyrax.config).to receive_messages(flexible?: true, controlled_vocabulary_label_service: label_service)
    allow(Hyrax::FlexibleSchema).to receive_message_chain(:order, :last).with('created_at asc').with(2)
                                                                     .and_return([schema.call(first_profile)],
                                                                                 [schema.call(first_profile), schema.call(second_profile)])
  end

  describe 'a config handed out before a later load' do
    let(:handed_out) do
      controller.class.load_flexible_schema
      controller.class.blacklight_config
    end

    it 'keeps its facets when the later load drops a property' do
      facets = handed_out.facet_fields.keys

      controller.class.load_flexible_schema

      expect(handed_out.facet_fields.keys).to eq facets
      expect(controller.class.blacklight_config.facet_fields).not_to include('resource_type_label_sim')
    end

    it 'keeps its keyword search fields when the later load adds a property' do
      qf = handed_out.search_fields['all_fields'].solr_parameters[:qf].dup

      controller.class.load_flexible_schema

      expect(handed_out.search_fields['all_fields'].solr_parameters[:qf]).to eq qf
      expect(controller.class.blacklight_config.search_fields['all_fields'].solr_parameters[:qf]).to include('shelf_mark_tesim')
    end
  end

  describe 'a load that starts after another profile was swapped in' do
    before do
      allow(Hyrax::FlexibleSchema).to receive_message_chain(:order, :last).with('created_at asc').with(2)
                                                                       .and_return([schema.call(first_profile)])
    end

    it "builds only its own profile's fields, without the other profile's property" do
      controller.class.load_flexible_schema
      controller.class.blacklight_config.add_facet_field('shelf_mark_sim', label: 'Shelf Mark')

      expect(controller.class.load_flexible_schema.facet_fields).not_to include('shelf_mark_sim')
    end

    it "gives a subclass configured after that load the configuration rather than the loaded profile's fields" do
      controller.class.load_flexible_schema
      controller.class.blacklight_config.add_facet_field('shelf_mark_sim', label: 'Shelf Mark')

      expect(Class.new(controller.class).blacklight_config.facet_fields).not_to include('shelf_mark_sim', 'resource_type_label_sim')
    end
  end

  it 'loads a subclass before its superclass has captured a baseline' do
    subclass = Class.new(controller.class)

    expect(subclass.load_flexible_schema.facet_fields).to include('resource_type_label_sim')
  end

  it "renders a request with the config its own load built, though another request's config replaces it first" do
    allow(controller.class).to receive(:load_flexible_schema).and_wrap_original do |load|
      built = load.call
      controller.class.blacklight_config = Blacklight::Configuration.new
      built
    end

    expect(controller.class.new.blacklight_config.facet_fields).to include('resource_type_label_sim')
  end
end
