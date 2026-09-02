# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FlexibleCatalogBehavior, 'name: surrogate properties', type: :controller do
  let(:base_profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }

  let(:custom_properties) do
    YAML.safe_load(<<-YAML)
      properties:
        resource_type:
          available_on:
            class:
              - GenericWork
          display_label:
            default: Resource Type
          indexing:
            - stored_searchable
            - facetable
          property_uri: http://purl.org/dc/terms/type
          range: http://www.w3.org/2001/XMLSchema#string
        monograph_resource_type:
          name: resource_type
          available_on:
            class:
              - Monograph
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

  controller(ApplicationController) do
    include Blacklight::Configurable
    include Blacklight::SearchContext
    include Hyrax::FlexibleCatalogBehavior

    configure_blacklight do |config|
      config.search_builder_class = Hyrax::CatalogSearchBuilder
      config.default_solr_params = { qt: 'search', rows: 10 }

      config.add_search_field('all_fields') do |field|
        field.solr_parameters = { qf: String.new('') }
      end
    end

    def index
      @response = Blacklight::Solr::Response.new({}, {})
      render plain: 'OK'
    end
  end

  # blacklight_config is class-level state, so without this a facet registered
  # by one example is still there for the next.
  around do |example|
    klass = self.class.controller_class
    original = klass.blacklight_config.deep_copy
    example.run
    klass.blacklight_config = original
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    routes.draw { get 'index' => 'anonymous#index' }

    mock_schema = double('FlexibleSchema', profile: base_profile.deep_merge(custom_properties))

    allow(Hyrax::FlexibleSchema)
      .to receive_message_chain(:order, :last)
      .with("created_at asc")
      .with(2)
      .and_return([mock_schema])

    controller.class.load_flexible_schema
  end

  let(:blacklight_config) do
    get :index
    controller.blacklight_config
  end

  it 'registers no facet under the surrogate key, where nothing is indexed' do
    expect(blacklight_config.facet_fields).not_to have_key('monograph_resource_type_sim')
  end

  it 'registers no search-result column under the surrogate key' do
    expect(blacklight_config.index_fields).not_to have_key('monograph_resource_type_tesim')
  end

  it 'registers the attribute the surrogate stands in for' do
    expect(blacklight_config.facet_fields).to have_key('resource_type_sim')
    expect(blacklight_config.index_fields).to have_key('resource_type_tesim')
  end

  it 'is safe to run once per request' do
    expect { 5.times { controller.class.load_flexible_schema } }.not_to raise_error

    expect(blacklight_config.facet_fields).not_to have_key('monograph_resource_type_sim')
    expect(blacklight_config.facet_fields).to have_key('resource_type_sim')
  end
end
