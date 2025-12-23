# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FlexibleCatalogBehavior, type: :controller do
  let(:base_profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }

  # adds additional properties to the base profile to
  # include properties that do not exist in the blacklight
  # config with various indexing and view options
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
          property_uri: http://example.org/related_resource
          range: http://www.w3.org/2001/XMLSchema#string
          view:
            render_as: external_link
            html_dl: true
        medium:
          available_on:
            class:
              - GenericWork
              - Monograph
          display_label:
            default: Medium
          indexing:
            - medium_tesim
            - medium_sim
          property_uri: http://purl.org/dc/terms/relation
          range: http://www.w3.org/2001/XMLSchema#string
          view:
            render_as: linked
            html_dl: true
    YAML
  end

  controller(ApplicationController) do
    include Blacklight::Configurable
    include Blacklight::SearchContext
    include Hyrax::FlexibleCatalogBehavior

    configure_blacklight do |config|
      config.search_builder_class = Hyrax::CatalogSearchBuilder
      config.default_solr_params = { qt: 'search', rows: 10 }

      # tests the scenario where all properties need to be added dynamically
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
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      routes.draw { get 'index' => 'anonymous#index' }

      # mock the schema retrieval to avoid database interactions
      mock_schema = double('FlexibleSchema',
        profile: base_profile.deep_merge(custom_properties))

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

    context 'properties with indexing' do
      it 'are checked for existence in the blacklight config' do
        # metadata properties from spec/fixtures/files/m3_profile.yaml
        %w[title_tesim depositor_tesim creator_tesim label_tesim keyword_tesim abstract_tesim].each do |field|
          expect(blacklight_config.index_fields).to have_key(field)
        end
      end

      it 'are added to the blacklight config' do
        # metadata properties from custom_properties should be added then checked for existence in the blacklight config
        %w[publication_date_tesim department_tesim related_resource_tesim medium_tesim].each do |field|
          expect(blacklight_config.index_fields).to have_key(field)
        end
      end

      it 'have a label property in blacklight config' do
        # gets the display_label from the metadata profile and adds it as the label attribute in blacklight config
        expected_labels = {
          'depositor_tesim' => 'Depositor',
          'creator_tesim' => 'Creator',
          'label_tesim' => 'Label',
          'abstract_tesim' => 'Abstract',
          'department_tesim' => 'Department',
          'publication_date_tesim' => 'Publication Date',
          'medium_tesim' => 'Medium',
          'related_resource_tesim' => 'Related Resource'
        }

        expected_labels.each do |field, label|
          expect(blacklight_config.index_fields[field].label).to eq(label)
        end
      end

      it 'have an itemprop property added to the blacklight config' do
        # itemprop is the property name that gets mapped to the Solr field name
        %w[title depositor creator label abstract publication_date department related_resource medium].each do |field|
          expect(blacklight_config.index_fields[field + '_tesim'].itemprop).to eq(field)
        end
      end

      it 'adds helper methods for properties with render_as view options' do
        # related_resource_tesim should have iconify_auto_link helper
        expect(blacklight_config.index_fields['related_resource_tesim'].helper_method).to eq(:iconify_auto_link)
        expect(blacklight_config.index_fields['related_resource_tesim'].field_name).to eq('related_resource')

        # medium_tesim should have index_field_link helper
        expect(blacklight_config.index_fields['medium_tesim'].helper_method).to eq(:index_field_link)
        expect(blacklight_config.index_fields['medium_tesim'].field_name).to eq('medium')

        # department_tesim should not have helper methods
        expect(blacklight_config.index_fields['department_tesim'].helper_method).to be_nil
      end

      it 'have the render_in_tenant? condition added to the blacklight config' do
        # all fields should have the render_in_tenant? condition
        # this allows admins to hide properties from catalog search results via the UI
        %w[publication_date_tesim department_tesim related_resource_tesim medium_tesim].each do |field|
          expect(blacklight_config.index_fields[field].if).to eq(:render_in_tenant?)
        end
      end
    end

    context 'properties with sidebar faceting' do
      it 'have a facet field added to the blacklight config' do
        # if the  property has facetable in the indexing section of the metadata profile, ensure the _sim field is added to the blacklight config
        %w[keyword publication_date department].each do |field|
          expect(blacklight_config.facet_fields).to have_key(field + '_sim')
        end

        # verify non-facetable properties don't have facet fields
        %w[related_resource medium].each do |field|
          expect(blacklight_config.facet_fields).not_to have_key(field + '_sim')
        end
      end

      it 'have a link_to_facet property added to the blacklight config' do
        # if the property has render_as: linked ensure the link_to_facet has the _sim field name
        %w[keyword publication_date department].each do |field|
          expect(blacklight_config.index_fields[field + '_tesim'].link_to_facet).to eq(field + '_sim')
        end
      end

      context 'when a property changes from facetable to non-facetable' do
        it 'removes the facet field from blacklight config' do
          # manually add a facet field (simulating it existing in CatalogController)
          controller.class.blacklight_config.add_facet_field('medium_sim', label: 'Medium')

          # verify it exists
          expect(controller.class.blacklight_config.facet_fields).to have_key('medium_sim')

          # reload the schema (medium is not facetable in custom_properties)
          controller.class.load_flexible_schema

          # should not exist since medium doesn't have 'facetable' in indexing
          expect(controller.class.blacklight_config.facet_fields).not_to have_key('medium_sim')
        end
      end
    end

    context 'search fields' do
      it 'have the properties added to the search qf parameter' do
        qf = blacklight_config.search_fields['all_fields'].solr_parameters[:qf]

        # verify the custom_properties are added to the search query fields
        %w[title_tesim publication_date_tesim department_tesim related_resource_tesim medium_tesim].each do |field|
          expect(qf).to include(field)
        end
      end
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
