# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FlexibleCatalogBehavior, 'controlled vocabulary labels', type: :controller do
  let(:base_profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }

  let(:custom_properties) do
    YAML.safe_load(<<-YAML)
      properties:
        resource_type:
          available_on:
            class:
              - GenericWork
              - Monograph
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
              - resource_types
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
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
              - monograph_types
          display_label:
            default: Resource Type
          indexing:
            - resource_type_sim
            - resource_type_tesim
            - stored_searchable
            - facetable
          property_uri: http://purl.org/dc/terms/type
          range: http://www.w3.org/2001/XMLSchema#string
        profile_only:
          available_on:
            class:
              - GenericWork
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
              - resource_types
          display_label:
            default: Profile Only
          indexing:
            - profile_only_sim
            - profile_only_tesim
            - facetable
          property_uri: http://example.org/profile_only
          range: http://www.w3.org/2001/XMLSchema#string
        free_text_note:
          available_on:
            class:
              - GenericWork
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
              - "null"
          display_label:
            default: Free Text Note
          indexing:
            - stored_searchable
            - facetable
          property_uri: http://example.org/free_text_note
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

      config.add_index_field 'app_helper_type_tesim', helper_method: :an_application_helper
    end

    def index
      @response = Blacklight::Solr::Response.new({}, {})
      render plain: 'OK'
    end
  end

  let(:label_service) do
    Class.new(Hyrax::ControlledVocabularyLabelService) do
      def resolvable?(source)
        ['resource_types', 'monograph_types'].include?(source)
      end
    end.new
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
    allow(Hyrax.config).to receive(:controlled_vocabulary_label_service).and_return(label_service)
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

  def would_render?(facet_name)
    field = blacklight_config.facet_fields[facet_name]
    return false if field.blank?

    Blacklight::Configuration::Context.new(controller)
                                      .evaluate_if_unless_configuration(field, nil)
  end

  describe 'a facetable controlled property' do
    it 'facets on the label field' do
      expect(blacklight_config.facet_fields).to have_key('resource_type_label_sim')
    end

    it 'links the search-result row to the label facet' do
      expect(blacklight_config.index_fields['resource_type_tesim'].link_to_facet)
        .to eq('resource_type_label_sim')
    end

    it 'resolves the facet label rather than titleizing the renamed solr key' do
      stored = blacklight_config.facet_fields['resource_type_label_sim'].label
      resolved = stored.respond_to?(:call) ? stored.call : stored

      expect(resolved).to match(/\AResource [Tt]ype\z/)
    end

    it 'shows the label in the search-result row, falling back to the id' do
      field = blacklight_config.index_fields['resource_type_tesim']
      expect(field.values).to be_present

      document = { 'resource_type_tesim' => ['local_auth_123'],
                   'resource_type_label_tesim' => ['Opaque Term'] }
      expect(field.values.call(field, document, nil)).to eq(['Opaque Term'])

      unlabeled = { 'resource_type_tesim' => ['local_auth_123'] }
      expect(field.values.call(field, unlabeled, nil)).to eq(['local_auth_123'])
    end
  end

  describe 'the id facet' do
    it 'stays registered so an un-reindexed corpus keeps its facet' do
      expect(blacklight_config.facet_fields).to have_key('resource_type_sim')
      expect(blacklight_config.facet_fields).to have_key('resource_type_label_sim')
    end

    it 'keeps existing bookmarked and saved-search facet URLs working' do
      expect(blacklight_config.facet_fields['resource_type_sim']).to be_present
    end
  end

  describe 'the id facet, once a label facet exists' do
    it 'stays configured so saved searches and bookmarks keep resolving' do
      expect(blacklight_config.facet_fields).to have_key('resource_type_sim')
    end

    it 'is not listed in the sidebar, so the ids are not shown beside the labels' do
      expect(would_render?('resource_type_sim')).to be false
    end

    it 'leaves the label facet listed' do
      expect(would_render?('resource_type_label_sim')).to be true
    end
  end

  describe 'a controlled property declaring only shorthand indexing directives' do
    let(:custom_properties) do
      YAML.safe_load(<<-YAML)
        properties:
          shorthand_type:
            available_on:
              class:
                - GenericWork
                - Monograph
            controlled_values:
              format: http://www.w3.org/2001/XMLSchema#string
              sources:
                - resource_types
            display_label:
              default: Shorthand Type
            indexing:
              - stored_searchable
              - facetable
            property_uri: http://purl.org/dc/terms/type
            range: http://www.w3.org/2001/XMLSchema#string
      YAML
    end

    it 'registers no label facet, because nothing is indexed to one' do
      expect(blacklight_config.facet_fields).not_to have_key('shorthand_type_label_sim')
    end

    it 'leaves the id facet listed rather than hiding it behind an empty one' do
      expect(blacklight_config.facet_fields['shorthand_type_sim'].show).not_to be false
    end
  end

  describe 'a controlled property declaring only a stored key, no facet key' do
    let(:custom_properties) do
      YAML.safe_load(<<-YAML)
        properties:
          mixed_type:
            available_on:
              class:
                - GenericWork
                - Monograph
            controlled_values:
              format: http://www.w3.org/2001/XMLSchema#string
              sources:
                - resource_types
            display_label:
              default: Mixed Type
            indexing:
              - mixed_type_tesim
              - facetable
            property_uri: http://purl.org/dc/terms/type
            range: http://www.w3.org/2001/XMLSchema#string
      YAML
    end

    it 'registers no label facet, because no label facet field is indexed' do
      expect(blacklight_config.facet_fields).not_to have_key('mixed_type_label_sim')
    end

    it 'leaves the id facet listed' do
      expect(blacklight_config.facet_fields['mixed_type_sim'].show).not_to be false
    end
  end

  describe 'a property the application already configured a helper for' do
    let(:custom_properties) do
      YAML.safe_load(<<-YAML)
        properties:
          app_helper_type:
            available_on:
              class:
                - GenericWork
            controlled_values:
              sources:
                - resource_types
            display_label:
              default: App Helper Type
            indexing:
              - app_helper_type_sim
              - app_helper_type_tesim
            view:
              render_as: external_link
      YAML
    end

    it 'keeps the helper the application declared' do
      expect(blacklight_config.index_fields['app_helper_type_tesim'].helper_method)
        .to eq :an_application_helper
    end

    it 'leaves the stored id for that helper to render' do
      expect(blacklight_config.index_fields['app_helper_type_tesim'].values).to be_nil
    end
  end

  describe 'a property that stops being controlled' do
    let(:config) { controller.class.blacklight_config }

    it 'restores the id facet to the sidebar' do
      expect(config.facet_fields['resource_type_sim'].if).to be false

      allow(Hyrax.config).to receive(:controlled_vocabulary_label_service)
        .and_return(Hyrax::ControlledVocabularyLabelService.new)
      controller.class.load_flexible_schema

      expect(config.facet_fields['resource_type_sim'].if).not_to be false
    end
  end

  describe 'free-text search' do
    let(:qf) { blacklight_config.search_fields['all_fields'].solr_parameters[:qf] }

    it 'queries the label field, so searching a term by its label finds the work' do
      expect(qf).to include('resource_type_label_tesim')
    end

    it 'still queries the id field' do
      expect(qf).to include('resource_type_tesim')
    end

    it 'does not add a label field for an uncontrolled property' do
      expect(qf).not_to include('free_text_note_label_tesim')
    end
  end

  describe 'a property that stops being controlled' do
    let(:config) { controller.class.blacklight_config }

    before do
      expect(config.index_fields['resource_type_tesim'].values).to be_present

      allow(Hyrax.config).to receive(:controlled_vocabulary_label_service)
        .and_return(Hyrax::ControlledVocabularyLabelService.new)
      controller.class.load_flexible_schema
    end

    it 'stops reading the label field in search results' do
      expect(config.index_fields['resource_type_tesim'].values).to be_nil
    end
  end

  describe 'the free-text search fields' do
    let(:qf) { blacklight_config.search_fields['all_fields'].solr_parameters[:qf] }

    it 'appends a field whose name is a substring of one already listed' do
      # A substring check reports `type_tesim` as present once
      # `resource_type_tesim` is in the list, so it would never be appended.
      qf # resolve the config before appending
      controller.class.send(:append_query_fields!, ['type_tesim'])

      current = controller.class.blacklight_config.search_fields['all_fields'].solr_parameters[:qf]
      expect(current.split).to include('type_tesim', 'resource_type_tesim')
    end
  end

  describe 'a property whose first source is not resolvable' do
    let(:custom_properties) do
      YAML.safe_load(<<-YAML)
        properties:
          mixed_sources:
            available_on:
              class:
                - GenericWork
                - Monograph
            controlled_values:
              format: http://www.w3.org/2001/XMLSchema#string
              sources:
                - geonames
                - resource_types
            display_label:
              default: Mixed Sources
            indexing:
              - mixed_sources_sim
              - mixed_sources_tesim
              - facetable
            property_uri: http://purl.org/dc/terms/type
            range: http://www.w3.org/2001/XMLSchema#string
      YAML
    end

    it 'agrees with the indexer, which resolves the first real source' do
      expect(blacklight_config.facet_fields).not_to have_key('mixed_sources_label_sim')
      expect(blacklight_config.facet_fields['mixed_sources_sim'].show).not_to be false
    end
  end

  describe 'removing a property from the query fields' do
    let(:config) { controller.class.blacklight_config }
    let(:qf) { config.search_fields['all_fields'].solr_parameters[:qf] }

    # Substring removal would take `resource_type_tesim` down to `resource_`
    # when asked to remove the shorter `type_tesim`.
    it 'leaves a longer field whose name contains the removed one intact' do
      controller.class.send(:append_query_fields!, ['type_tesim'])
      expect(qf.split).to include('type_tesim', 'resource_type_tesim')

      controller.class.send(:remove_from_blacklight_config!, 'type', ['type_tesim'])

      expect(qf.split).not_to include('type_tesim')
      expect(qf.split).to include('resource_type_tesim')
    end
  end

  describe 'an uncontrolled property' do
    it 'keeps faceting on its own solr key' do
      expect(blacklight_config.facet_fields).to have_key('free_text_note_sim')
      expect(blacklight_config.facet_fields).not_to have_key('free_text_note_label_sim')
    end

    it 'is left reading the stored values' do
      expect(blacklight_config.index_fields['free_text_note_tesim'].values).to be_nil
    end
  end

  describe 'a name: surrogate property' do
    it 'registers no facet under its own key, where nothing is indexed' do
      expect(blacklight_config.facet_fields).not_to have_key('monograph_resource_type_sim')
      expect(blacklight_config.facet_fields).not_to have_key('monograph_resource_type_label_sim')
    end
  end

  describe 'resolvable? lookups' do
    it 'asks the label service once per distinct vocabulary, not once per property' do
      allow(label_service).to receive(:resolvable?).and_call_original

      controller.class.load_flexible_schema

      expect(label_service).to have_received(:resolvable?).with('resource_types').at_most(:once)
    end
  end

  describe 'a surrogate declaring the target attribute\'s solr fields' do
    it 'does not delete the target property\'s own registrations' do
      expect(blacklight_config.facet_fields).to have_key('resource_type_sim')
      expect(blacklight_config.index_fields).to have_key('resource_type_tesim')
    end
  end

  describe 'a controlled property that leaves the profile' do
    let(:config) { controller.class.blacklight_config }

    before do
      expect(config.facet_fields).to have_key('resource_type_label_sim')
      controller.class.send(:remove_from_blacklight_config!, 'resource_type',
                            ['stored_searchable', 'facetable'])
    end

    it 'removes its label facet along with its id facet' do
      expect(config.facet_fields).not_to have_key('resource_type_label_sim')
      expect(config.facet_fields).not_to have_key('resource_type_sim')
    end

    it 'removes its label column along with its id column' do
      expect(config.index_fields).not_to have_key('resource_type_label_tesim')
      expect(config.index_fields).not_to have_key('resource_type_tesim')
    end
  end

  describe 'a property that becomes a surrogate mid-process' do
    let(:config) { controller.class.blacklight_config }

    it 'leaves no label facet behind under the surrogate key' do
      config.add_facet_field('monograph_resource_type_label_sim', label: 'Stale')

      controller.class.load_flexible_schema

      expect(config.facet_fields).not_to have_key('monograph_resource_type_label_sim')
      expect(config.facet_fields).not_to have_key('monograph_resource_type_sim')
    end
  end

  describe 'repeated loads' do
    it 'is safe to run once per request' do
      expect { 5.times { controller.class.load_flexible_schema } }.not_to raise_error

      expect(blacklight_config.facet_fields).to have_key('resource_type_label_sim')
    end
  end

  context 'with no label service registered' do
    let(:label_service) { Hyrax::ControlledVocabularyLabelService.new }

    it 'leaves the catalog config exactly as upstream builds it' do
      expect(blacklight_config.facet_fields).to have_key('resource_type_sim')
      expect(blacklight_config.facet_fields).not_to have_key('resource_type_label_sim')
      expect(blacklight_config.index_fields['resource_type_tesim'].values).to be_nil
    end
  end

  describe 'a property whose render_as changes between profiles' do
    # blacklight_config is class-level and only rebuilt for properties that left
    # the profile, so a property that merely changed keeps the previous
    # profile's registration until the process restarts.
    def load_with_render_as(render_as, property: 'monograph_resource_type')
      profile = base_profile.deep_merge(custom_properties)
      property = profile['properties'][property]
      property['view'] = render_as ? { 'render_as' => render_as, 'html_dl' => true } : { 'html_dl' => true }

      allow(Hyrax::FlexibleSchema)
        .to receive_message_chain(:order, :last)
        .with("created_at asc")
        .with(2)
        .and_return([double('FlexibleSchema', profile:)])

      controller.class.load_flexible_schema
    end

    it 'clears the helper when the new profile declares no render_as' do
      load_with_render_as('linked')
      expect(controller.class.blacklight_config.index_fields['resource_type_tesim'].helper_method)
        .to eq :index_field_link

      load_with_render_as(nil)

      expect(controller.class.blacklight_config.index_fields['resource_type_tesim'].helper_method).to be_nil
    end

    it 'replaces the helper when the new profile declares a different render_as' do
      load_with_render_as('linked')
      load_with_render_as('external_link')

      expect(controller.class.blacklight_config.index_fields['resource_type_tesim'].helper_method)
        .to eq :iconify_auto_link
    end

    it 'leaves an application-configured helper alone' do
      load_with_render_as('linked')
      load_with_render_as(nil)

      expect(controller.class.blacklight_config.index_fields['app_helper_type_tesim'].helper_method)
        .to eq :an_application_helper
    end

    it 'clears the helper on a field the profile itself created' do
      load_with_render_as('linked', property: 'profile_only')
      expect(controller.class.blacklight_config.index_fields['profile_only_tesim'].helper_method)
        .to eq :index_field_link

      load_with_render_as(nil, property: 'profile_only')

      expect(controller.class.blacklight_config.index_fields['profile_only_tesim'].helper_method).to be_nil
    end
  end

  describe 'a facet the application already conditioned' do
    before do
      controller.class.blacklight_config.add_facet_field('conditioned_sim', label: 'Conditioned', if: :render_optionally?)
    end

    def load_conditioned(controlled:)
      profile = base_profile.deep_merge(custom_properties)
      profile['properties']['conditioned'] = {
        'available_on' => { 'class' => ['GenericWork'] },
        'controlled_values' => { 'format' => 'http://www.w3.org/2001/XMLSchema#string',
                                 'sources' => [controlled ? 'resource_types' : 'null'] },
        'display_label' => { 'default' => 'Conditioned' },
        'indexing' => ['conditioned_sim', 'conditioned_tesim', 'facetable'],
        'property_uri' => 'http://example.org/conditioned',
        'range' => 'http://www.w3.org/2001/XMLSchema#string'
      }

      allow(Hyrax::FlexibleSchema)
        .to receive_message_chain(:order, :last)
        .with("created_at asc")
        .with(2)
        .and_return([double('FlexibleSchema', profile:)])

      controller.class.load_flexible_schema
    end

    it "restores the application's own predicate when the property stops being controlled" do
      load_conditioned(controlled: true)
      expect(controller.class.blacklight_config.facet_fields['conditioned_sim'].if).to be false

      load_conditioned(controlled: false)

      expect(controller.class.blacklight_config.facet_fields['conditioned_sim'].if).to eq :render_optionally?
    end
  end
end
