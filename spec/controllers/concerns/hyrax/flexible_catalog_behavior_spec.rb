# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FlexibleCatalogBehavior, type: :controller do
  let(:base_profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }

  let(:custom_properties) do
    YAML.safe_load(<<-YAML)
      properties:
        publication_date:
          available_on:
            class:
              - GenericWork
              - Monograph
          display_label:
            default: Publication Date
          indexing:
            - stored_searchable
            - facetable
          property_uri: http://purl.org/dc/terms/date
          range: http://www.w3.org/2001/XMLSchema#string
        department:
          available_on:
            class:
              - GenericWork
          display_label:
            default: Department
          indexing:
            - department_tesim
            - department_sim
            - facetable
          property_uri: http://example.org/department
          range: http://www.w3.org/2001/XMLSchema#string
          view:
            html_dl: true
        external_link:
          available_on:
            class:
              - GenericWork
              - Monograph
          display_label:
            default: External Link
          indexing:
            - external_link_tesim
            - external_link_sim
          property_uri: http://example.org/external_link
          range: http://www.w3.org/2001/XMLSchema#string
          view:
            render_as: external_link
            html_dl: true
        related_resource:
          available_on:
            class:
              - GenericWork
              - Monograph
          display_label:
            default: Related Resource
          indexing:
            - related_resource_tesim
            - related_resource_sim
          property_uri: http://purl.org/dc/terms/relation
          range: http://www.w3.org/2001/XMLSchema#string
          view:
            render_as: linked
            html_dl: true
    YAML
  end

  before do
    # Clean up any existing schemas
    Hyrax::FlexibleSchema.destroy_all

    # Enable flexible metadata
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
  end

  after do
    Hyrax::FlexibleSchema.destroy_all
  end

  controller(ApplicationController) do
    include Blacklight::Configurable
    include Blacklight::SearchContext
    include Hyrax::FlexibleCatalogBehavior # rubocop:disable RSpec/DescribedClass

    configure_blacklight do |config|
      config.search_builder_class = Hyrax::CatalogSearchBuilder
      config.default_solr_params = { qt: 'search', rows: 10 }

      # Start with a clean blacklight config - no pre-existing index fields
      # This tests the scenario where all properties need to be added dynamically
      config.add_search_field('all_fields') do |field|
        field.solr_parameters = { qf: String.new('') }
      end
    end

    def index
      @response = Blacklight::Solr::Response.new({}, {})
      render plain: 'OK'
    end
  end

  describe 'loading flexible metadata profile' do
    before do
      routes.draw { get 'index' => 'anonymous#index' }
    end

    before do
      # Create the schema in the database by merging base profile with custom properties
      Hyrax::FlexibleSchema.create!(profile: base_profile.deep_merge(custom_properties))

      # Manually trigger load_flexible_schema since it's a class method that runs once
      # We need to call it after the schema is created
      controller.class.load_flexible_schema

      get :index
      blacklight_config = controller.blacklight_config
    end


    # title - has indexing: title_sim, title_tesim (facetable)
    # date_modified - no indexing defined
    # date_uploaded - no indexing defined
    # depositor - has indexing: depositor_tesim, depositor_ssim
    # creator - has indexing: creator_sim, creator_tesim (facetable)
    # label - has indexing: label_sim, label_tesim (facetable)
    # keyword - has indexing: keyword_sim, keyword_tesim (facetable), has view: render_as: "faceted"
    # abstract - has indexing: abstract_sim, abstract_tesim (facetable)
    # publication_date - has indexing: publication_date_tesim, publication_date_sim (facetable)
    # department - has indexing: department_tesim, department_sim (facetable)
    # external_link - has indexing: external_link_tesim, external_link_sim
    # related_resource - has indexing: related_resource_tesim, related_resource_sim



    it 'loads flexible schema properties into blacklight config' do
#<Blacklight::Configuration::IndexField label="Title", itemprop="name", if=:render_in_tenant?, key="title_tesim", field="title_tesim", unless=false, presenter=Blacklight::FieldPresenter>
#<Blacklight::Configuration::IndexField label="Owner", helper_method=:link_to_profile, if=:render_in_tenant?, key="depositor_tesim", field="depositor_tesim", unless=false, presenter=Blacklight::FieldPresenter>


      expect(blacklight_config.index_fields).to have_key('title_tesim')
      expect(blacklight_config.index_fields).to have_key('depositor_tesim')
      expect(blacklight_config.index_fields).to have_key('creator_tesim')
      expect(blacklight_config.index_fields).to have_key('label_tesim')
      expect(blacklight_config.index_fields).to have_key('keyword_tesim')
      expect(blacklight_config.index_fields).to have_key('abstract_tesim')
      expect(blacklight_config.index_fields).to have_key('publication_date_tesim')
      expect(blacklight_config.index_fields).to have_key('department_tesim')
      expect(blacklight_config.index_fields).to have_key('external_link_tesim')
      expect(blacklight_config.index_fields).to have_key('related_resource_tesim')
    end

    it 'sets correct labels for index fields' do
      get :index

      blacklight_config = controller.blacklight_config

      expect(blacklight_config.index_fields['title_tesim'].label).to eq('Title')
      expect(blacklight_config.index_fields['depositor_tesim'].label).to eq('Depositor')
      expect(blacklight_config.index_fields['creator_tesim'].label).to eq('Creator')
      expect(blacklight_config.index_fields['label_tesim'].label).to eq('Label')
      expect(blacklight_config.index_fields['keyword_tesim'].label).to eq('Keyword')
      expect(blacklight_config.index_fields['abstract_tesim'].label).to eq('Abstract')
      expect(blacklight_config.index_fields['publication_date_tesim'].label).to eq('Publication Date')
      expect(blacklight_config.index_fields['department_tesim'].label).to eq('Department')
      expect(blacklight_config.index_fields['external_link_tesim'].label).to eq('External Link')
      expect(blacklight_config.index_fields['publication_date_tesim'].label).to eq('Publication Date')
      expect(blacklight_config.index_fields['department_tesim'].label).to eq('Department')
      expect(blacklight_config.index_fields['external_link_tesim'].label).to eq('External Link')
      expect(blacklight_config.index_fields['related_resource_tesim'].label).to eq('Related Resource')
    end

    it 'sets itemprop for index fields' do
      get :index

      blacklight_config = controller.blacklight_config

      expect(blacklight_config.index_fields['title_tesim'].itemprop).to eq('title')
      expect(blacklight_config.index_fields['author_name_tesim'].itemprop).to eq('author_name')
      expect(blacklight_config.index_fields['publication_date_tesim'].itemprop).to eq('publication_date')
    end

    it 'adds facet fields for facetable properties' do
      get :index

      blacklight_config = controller.blacklight_config

      # Verify facet fields are added for facetable properties
      expect(blacklight_config.facet_fields).to have_key('title_sim')
      expect(blacklight_config.facet_fields).to have_key('publication_date_sim')
      expect(blacklight_config.facet_fields).to have_key('department_sim')

      # Verify non-facetable properties don't have facet fields
      expect(blacklight_config.facet_fields).not_to have_key('author_name_sim')
      expect(blacklight_config.facet_fields).not_to have_key('external_link_sim')
    end

    it 'sets link_to_facet for facetable index fields' do
      get :index

      blacklight_config = controller.blacklight_config

      expect(blacklight_config.index_fields['title_tesim'].link_to_facet).to eq('title_sim')
      expect(blacklight_config.index_fields['publication_date_tesim'].link_to_facet).to eq('publication_date_sim')
      expect(blacklight_config.index_fields['department_tesim'].link_to_facet).to eq('department_sim')
    end

    it 'adds properties to search qf parameter' do
      get :index

      blacklight_config = controller.blacklight_config
      qf = blacklight_config.search_fields['all_fields'].solr_parameters[:qf]

      # Verify all 6 custom properties are added to the search query fields
      expect(qf).to include('title_tesim')
      expect(qf).to include('author_name_tesim')
      expect(qf).to include('publication_date_tesim')
      expect(qf).to include('department_tesim')
      expect(qf).to include('external_link_tesim')
      expect(qf).to include('related_resource_tesim')
    end

    it 'sets helper methods for fields with render_as view options' do
      get :index

      blacklight_config = controller.blacklight_config

      # External link should have iconify_auto_link helper
      expect(blacklight_config.index_fields['external_link_tesim'].helper_method).to eq(:iconify_auto_link)
      expect(blacklight_config.index_fields['external_link_tesim'].field_name).to eq('external_link')

      # Related resource should have index_field_link helper
      expect(blacklight_config.index_fields['related_resource_tesim'].helper_method).to eq(:index_field_link)
      expect(blacklight_config.index_fields['related_resource_tesim'].field_name).to eq('related_resource')

      # Regular fields should not have helper methods
      expect(blacklight_config.index_fields['author_name_tesim'].helper_method).to be_nil
    end

    it 'sets render_in_tenant? condition for all dynamically added index fields' do
      get :index

      blacklight_config = controller.blacklight_config

      # All dynamically added fields should have the render_in_tenant? condition
      # This allows admins to hide properties from catalog search results
      expect(blacklight_config.index_fields['title_tesim'].if).to eq(:render_in_tenant?)
      expect(blacklight_config.index_fields['author_name_tesim'].if).to eq(:render_in_tenant?)
      expect(blacklight_config.index_fields['publication_date_tesim'].if).to eq(:render_in_tenant?)
      expect(blacklight_config.index_fields['department_tesim'].if).to eq(:render_in_tenant?)
      expect(blacklight_config.index_fields['external_link_tesim'].if).to eq(:render_in_tenant?)
      expect(blacklight_config.index_fields['related_resource_tesim'].if).to eq(:render_in_tenant?)
    end
  end

  describe '.display_label_for' do
    it 'returns the display label from the config' do
      label = controller.class.send(:display_label_for, 'test_field',
                                     { 'display_label' => { 'default' => 'Test Label' } })
      expect(label).to eq('Test Label')
    end

    it 'returns humanized field name when display_label is blank' do
      label = controller.class.send(:display_label_for, 'test_field', {})
      expect(label).to eq('Test field')
    end

    it 'uses locale-specific label when available' do
      I18n.with_locale(:es) do
        label = controller.class.send(:display_label_for, 'test_field',
                                       { 'display_label' => { 'default' => 'Test Label', 'es' => 'Etiqueta de prueba' } })
        expect(label).to eq('Etiqueta de prueba')
      end
    end

    it 'falls back to default when locale-specific label is not available' do
      I18n.with_locale(:fr) do
        label = controller.class.send(:display_label_for, 'test_field',
                                       { 'display_label' => { 'default' => 'Test Label', 'es' => 'Etiqueta de prueba' } })
        expect(label).to eq('Test Label')
      end
    end
  end

  describe '.stored_searchable?' do
    it 'returns true when indexing includes stored_searchable' do
      result = controller.class.send(:stored_searchable?, ['stored_searchable'], 'test_field')
      expect(result).to be true
    end

    it 'returns true when indexing includes field_tesim' do
      result = controller.class.send(:stored_searchable?, ['test_field_tesim'], 'test_field')
      expect(result).to be true
    end

    it 'returns false when neither condition is met' do
      result = controller.class.send(:stored_searchable?, ['facetable'], 'test_field')
      expect(result).to be false
    end
  end

  describe '.facetable?' do
    it 'returns true when indexing includes facetable' do
      result = controller.class.send(:facetable?, ['facetable'], 'test_field')
      expect(result).to be true
    end

    it 'returns false when indexing does not include facetable' do
      result = controller.class.send(:facetable?, ['stored_searchable'], 'test_field')
      expect(result).to be false
    end
  end

  describe '.admin_only?' do
    it 'returns true when indexing includes admin_only' do
      result = controller.class.send(:admin_only?, ['admin_only', 'stored_searchable'])
      expect(result).to be true
    end

    it 'returns false when indexing does not include admin_only' do
      result = controller.class.send(:admin_only?, ['stored_searchable'])
      expect(result).to be false
    end
  end

  describe '.require_view_helper_method?' do
    it 'returns true for external_link render_as' do
      result = controller.class.send(:require_view_helper_method?, { 'render_as' => 'external_link' })
      expect(result).to be true
    end

    it 'returns true for linked render_as' do
      result = controller.class.send(:require_view_helper_method?, { 'render_as' => 'linked' })
      expect(result).to be true
    end

    it 'returns true for rights_statement render_as' do
      result = controller.class.send(:require_view_helper_method?, { 'render_as' => 'rights_statement' })
      expect(result).to be true
    end

    it 'returns false for other render_as values' do
      result = controller.class.send(:require_view_helper_method?, { 'render_as' => 'faceted' })
      expect(result).to be false
    end

    it 'returns false when view_options is nil' do
      result = controller.class.send(:require_view_helper_method?, nil)
      expect(result).to be false
    end
  end

  describe '.view_option_for_helper_method' do
    it 'returns :iconify_auto_link for external_link' do
      result = controller.class.send(:view_option_for_helper_method, { 'render_as' => 'external_link' })
      expect(result).to eq(:iconify_auto_link)
    end

    it 'returns :index_field_link for linked' do
      result = controller.class.send(:view_option_for_helper_method, { 'render_as' => 'linked' })
      expect(result).to eq(:index_field_link)
    end

    it 'returns :rights_statement_links for rights_statement' do
      result = controller.class.send(:view_option_for_helper_method, { 'render_as' => 'rights_statement' })
      expect(result).to eq(:rights_statement_links)
    end
  end
end

