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
        internal_note:
          available_on:
            class:
              - GenericWork
          display_label:
            default: Internal Note
          indexing:
            - stored_searchable
            - facetable
          property_uri: http://example.org/internal_note
          range: http://www.w3.org/2001/XMLSchema#string
          view:
            html_dl: true
            search_results: false
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
          stored = blacklight_config.index_fields[field].label
          resolved = stored.respond_to?(:call) ? stored.call : stored
          expect(resolved).to eq(label)
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

      it 'have the render_optionally? condition added to the blacklight config' do
        # all fields should have the render_optionally? condition
        # this allows a Hyku hook to hide properties from catalog search results
        %w[publication_date_tesim department_tesim related_resource_tesim medium_tesim].each do |field|
          expect(blacklight_config.index_fields[field].if).to eq(:render_optionally?)
        end
      end
    end

    context 'properties hidden from catalog search results' do
      it 'does not register an index field when view.search_results is false' do
        expect(blacklight_config.index_fields).not_to have_key('internal_note_tesim')
      end

      it 'does not add the property to the all_fields qf list' do
        qf = blacklight_config.search_fields['all_fields'].solr_parameters[:qf]
        expect(qf).not_to include('internal_note_tesim')
      end

      it 'still registers the facet field when indexing includes facetable' do
        expect(blacklight_config.facet_fields).to have_key('internal_note_sim')
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
    it 'returns a callable that resolves the default label' do
      label = controller.class.send(:display_label_for, 'test_field',
                                     { 'display_label' => { 'default' => 'Test Label' } })
      expect(label.call).to eq('Test Label')
    end

    it 'returns a callable that resolves to humanized field name when display_label is blank' do
      label = controller.class.send(:display_label_for, 'test_field', {})
      expect(label.call).to eq('Test field')
    end

    it 'resolves locale-specific label at call time when locale is :es' do
      label = controller.class.send(:display_label_for, 'test_field',
                                     { 'display_label' => { 'default' => 'Test Label', 'es' => 'Etiqueta de prueba' } })
      I18n.with_locale(:es) do
        expect(label.call).to eq('Etiqueta de prueba')
      end
    end

    it 'falls back to default when locale-specific label is not available' do
      label = controller.class.send(:display_label_for, 'test_field',
                                     { 'display_label' => { 'default' => 'Test Label', 'es' => 'Etiqueta de prueba' } })
      I18n.with_locale(:fr) do
        expect(label.call).to eq('Test Label')
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

  describe '.catalog_indexable?' do
    it 'returns false when view.search_results is false' do
      result = controller.class.send(:catalog_indexable?, { 'search_results' => false })
      expect(result).to be false
    end

    it 'returns true when view.search_results is true' do
      result = controller.class.send(:catalog_indexable?, { 'search_results' => true })
      expect(result).to be true
    end

    it 'returns true when view options do not include search_results' do
      result = controller.class.send(:catalog_indexable?, { 'html_dl' => true })
      expect(result).to be true
    end

    it 'returns true when view options are nil' do
      result = controller.class.send(:catalog_indexable?, nil)
      expect(result).to be true
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

  describe '.restricted_field?' do
    it 'is true when admin_only is in the indexing array' do
      expect(controller.class.send(:restricted_field?, ['title_tesim', 'stored_searchable', 'admin_only'])).to be true
    end

    it 'is true when editor_only is in the indexing array' do
      expect(controller.class.send(:restricted_field?, ['title_tesim', 'stored_searchable', 'editor_only'])).to be true
    end

    it 'is false when neither flag is present' do
      expect(controller.class.send(:restricted_field?, ['title_tesim', 'stored_searchable'])).to be false
    end
  end

  describe 'catalog registration of restricted fields' do
    let(:restricted_properties) do
      YAML.safe_load(<<-YAML)
        properties:
          secret_note:
            available_on:
              class:
                - GenericWork
                - Monograph
            display_label:
              default: Secret Note
            indexing:
              - secret_note_tesim
              - secret_note_sim
              - stored_searchable
              - facetable
              - editor_only
            property_uri: http://example.org/secret_note
            range: http://www.w3.org/2001/XMLSchema#string
      YAML
    end

    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      routes.draw { get 'index' => 'anonymous#index' }

      mock_schema = double('FlexibleSchema',
        profile: base_profile.deep_merge(restricted_properties))

      allow(Hyrax::FlexibleSchema)
        .to receive_message_chain(:order, :last)
        .with("created_at asc")
        .with(2)
        .and_return([mock_schema])

      controller.class.load_flexible_schema
      get :index
    end

    it 'does not add the field as an index column' do
      expect(controller.blacklight_config.index_fields).not_to have_key('secret_note_tesim')
    end

    it 'does not add the field as a facet' do
      expect(controller.blacklight_config.facet_fields).not_to have_key('secret_note_sim')
    end

    it 'does not add the field to the all_fields qf' do
      qf = controller.blacklight_config.search_fields['all_fields'].solr_parameters[:qf]
      expect(qf).not_to include('secret_note_tesim')
    end
  end

  describe '.remove_from_blacklight_config!' do
    let(:blacklight_config) { controller.class.blacklight_config }

    before { routes.draw { get 'index' => 'anonymous#index' } }

    describe 'all_fields qf cleanup' do
      # Registration appends fields as " #{name}", so by the time
      # remove_from_blacklight_config! runs, the field may be anywhere in the
      # qf string. The two slice! calls in the helper exist to cover all three
      # positions: middle (covered by the leading-space slice), first (no
      # leading space — covered by the bare slice), and only term (also no
      # leading space).
      before do
        controller.class.blacklight_config.search_fields['all_fields']
                  .solr_parameters[:qf] = qf_initial
      end

      let(:qf) { controller.class.blacklight_config.search_fields['all_fields'].solr_parameters[:qf] }

      context 'when the field is a middle term in qf' do
        let(:qf_initial) { String.new('title_tesim creator_tesim subject_tesim') }

        it 'removes the field and its preceding space' do
          controller.class.send(:remove_from_blacklight_config!, 'creator')
          expect(qf).to eq('title_tesim subject_tesim')
        end
      end

      context 'when the field is the first term in qf with no leading space' do
        let(:qf_initial) { String.new('creator_tesim title_tesim') }

        it 'removes the field even though there is no leading space to match' do
          controller.class.send(:remove_from_blacklight_config!, 'creator')
          expect(qf).not_to include('creator_tesim')
          expect(qf).to include('title_tesim')
        end
      end

      context 'when the field is the only term in qf' do
        let(:qf_initial) { String.new('creator_tesim') }

        it 'removes the field, leaving an empty qf' do
          controller.class.send(:remove_from_blacklight_config!, 'creator')
          expect(qf).to eq('')
        end
      end
    end

    describe 'multi-name cleanup driven by the indexing: array' do
      # When a property declares additional Solr field variants in its
      # indexing: array (e.g. a `_label_tesim` variant alongside the
      # canonical `_tesim`), the helper removes all of them — not just the
      # canonical pair synthesized from the itemprop. Directive flags like
      # `stored_searchable`/`facetable`/`admin_only`/`editor_only` are
      # filtered out and not treated as Solr field names.
      # Uses an itemprop unlikely to collide with the host app's default
      # CatalogController registrations; blacklight_config is a class-level
      # singleton shared across examples in this file.
      before do
        blacklight_config.add_index_field('memo_tesim', label: 'Memo') unless blacklight_config.index_fields.key?('memo_tesim')
        blacklight_config.add_index_field('memo_label_tesim', label: 'Memo Label') unless blacklight_config.index_fields.key?('memo_label_tesim')
        blacklight_config.add_facet_field('memo_sim', label: 'Memo') unless blacklight_config.facet_fields.key?('memo_sim')
        blacklight_config.add_facet_field('memo_label_sim', label: 'Memo Label') unless blacklight_config.facet_fields.key?('memo_label_sim')
        blacklight_config.search_fields['all_fields'].solr_parameters[:qf] =
          String.new('title_tesim memo_tesim memo_label_tesim')
      end

      let(:indexing) do
        ['memo_tesim', 'memo_sim', 'memo_label_tesim', 'memo_label_sim',
         'stored_searchable', 'facetable', 'editor_only']
      end

      it 'removes the canonical pair and all variants declared in indexing:' do
        controller.class.send(:remove_from_blacklight_config!, 'memo', indexing)

        expect(blacklight_config.index_fields).not_to have_key('memo_tesim')
        expect(blacklight_config.index_fields).not_to have_key('memo_label_tesim')
        expect(blacklight_config.facet_fields).not_to have_key('memo_sim')
        expect(blacklight_config.facet_fields).not_to have_key('memo_label_sim')

        qf = blacklight_config.search_fields['all_fields'].solr_parameters[:qf]
        expect(qf).to eq('title_tesim')
      end
    end

    describe 'prefix collision safety' do
      # A potential failure mode of prefix-based matching: `notes` cleanup
      # accidentally evicting unrelated `notes_internal_*` registrations.
      # The helper matches on *exact* Solr field names (canonical pair plus
      # explicit indexing: entries), so unrelated properties whose names
      # happen to start with the itemprop are untouched.
      #
      # Uses field names that are unlikely to collide with the host app's
      # CatalogController defaults; `blacklight_config` is a class-level
      # singleton shared across examples in this file, and re-registering a
      # field that already exists raises.
      before do
        blacklight_config.add_index_field('notes_tesim', label: 'Notes') unless blacklight_config.index_fields.key?('notes_tesim')
        blacklight_config.add_index_field('notes_internal_tesim', label: 'Internal Notes') unless blacklight_config.index_fields.key?('notes_internal_tesim')
        blacklight_config.add_facet_field('notes_internal_sim', label: 'Internal Notes') unless blacklight_config.facet_fields.key?('notes_internal_sim')
      end

      it 'does not remove a different property whose name starts with the same prefix' do
        controller.class.send(:remove_from_blacklight_config!, 'notes')

        expect(blacklight_config.index_fields).not_to have_key('notes_tesim')
        expect(blacklight_config.index_fields).to have_key('notes_internal_tesim')
        expect(blacklight_config.facet_fields).to have_key('notes_internal_sim')
      end
    end
  end
end
