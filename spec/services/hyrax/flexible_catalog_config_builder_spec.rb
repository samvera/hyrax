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
  let(:restricted_surrogate) { { 'indexing' => %w[stored_searchable facetable editor_only] } }
  let(:label_service) do
    Class.new(Hyrax::ControlledVocabularyLabelService) do
      def resolvable?(source)
        source == 'resource_types'
      end
    end.new
  end

  before { allow(Hyrax.config).to receive(:controlled_vocabulary_label_service).and_return(label_service) }

  def with_properties(properties)
    profile.deep_merge('properties' => properties)
  end

  describe '#apply' do
    it 'builds the profile onto the config it was given and returns that config' do
      expect(builder.apply(profile, profile)).to be config
      expect(config.facet_fields).to include('resource_type_label_sim')
    end

    it 'applies the previous profile when there is no current one' do
      builder.apply(profile, nil)

      expect(config.facet_fields).to include('resource_type_label_sim')
    end

    context 'with fields the configuration registers for a property' do
      before do
        config.add_facet_field('shelf_mark_sim')
        config.add_index_field('shelf_mark_tesim')
      end

      it 'removes them when the previous profile declared the property and the current one does not' do
        builder.apply(with_properties('shelf_mark' => { 'indexing' => %w[shelf_mark_sim shelf_mark_tesim] }), profile)

        expect(config.facet_fields).not_to include('shelf_mark_sim')
        expect(config.index_fields).not_to include('shelf_mark_tesim')
      end

      it 'removes them when a surrogate standing in for the property leaves the profile' do
        builder.apply(with_properties('monograph_shelf_mark' => restricted_surrogate.merge('name' => 'shelf_mark')), profile)

        expect(config.facet_fields).not_to include('shelf_mark_sim')
        expect(config.index_fields).not_to include('shelf_mark_tesim')
      end

      it 'removes them when a surrogate stops standing in for the property' do
        call_number = resource_type.merge(restricted_surrogate, 'name' => 'call_number', 'controlled_values' => { 'sources' => ['null'] })
        retargeted = with_properties('monograph_shelf_mark' => call_number)

        builder.apply(with_properties('monograph_shelf_mark' => restricted_surrogate.merge('name' => 'shelf_mark')), retargeted)

        expect(config.facet_fields).not_to include('shelf_mark_sim')
        expect(config.index_fields).not_to include('shelf_mark_tesim')
      end
    end

    it "removes a facet registered under a surrogate's own key" do
      config.add_facet_field('monograph_shelf_mark_label_sim')

      builder.apply(profile, with_properties('monograph_shelf_mark' => resource_type.merge('name' => 'shelf_mark')))

      expect(config.facet_fields).not_to include('monograph_shelf_mark_label_sim')
    end

    context 'with profile entries for one field, each overriding the one before' do
      let(:shelf_mark) do
        { 'available_on' => { 'class' => ['GenericWork'] },
          'controlled_values' => { 'sources' => ['null'] },
          'display_label' => { 'default' => 'Shelf Mark' },
          'indexing' => %w[shelf_mark_sim shelf_mark_tesim stored_searchable facetable],
          'property_uri' => 'http://example.org/shelf_mark',
          'range' => 'http://www.w3.org/2001/XMLSchema#string' }
      end
      let(:controlled) { { 'controlled_values' => { 'sources' => ['resource_types'] } } }
      let(:link_only) { { 'indexing' => %w[shelf_mark_sim shelf_mark_tesim stored_searchable], 'view' => { 'render_as' => 'faceted' } } }

      def apply_entries(*overrides, last)
        surrogates = overrides.each_with_index.to_h do |override, index|
          ["shelf_mark_#{index}", shelf_mark.merge('name' => 'shelf_mark').deep_merge(override)]
        end
        entries = with_properties(surrogates.merge('shelf_mark' => shelf_mark.deep_merge(last)))
        builder.apply(entries, entries)
      end

      it 'keeps a facet the application declared when an entry links to the label facet' do
        config.add_facet_field('shelf_mark_sim', label: 'Shelf Mark')

        apply_entries(link_only.merge(controlled))

        expect(config.facet_fields).to include('shelf_mark_sim')
      end

      it "keeps the application's predicate on a facet an entry asks to list" do
        config.add_facet_field('shelf_mark_sim', label: 'Shelf Mark', if: :render_optionally?)

        apply_entries({})

        expect(config.facet_fields['shelf_mark_sim'].if).to eq :render_optionally?
      end

      it "restores the application's predicate after two entries hid the facet" do
        config.add_facet_field('shelf_mark_sim', label: 'Shelf Mark', if: :render_optionally?)

        apply_entries(controlled, controlled, {})

        expect(config.facet_fields['shelf_mark_sim'].if).to eq :render_optionally?
      end

      it 'clears a link helper the first set when the second asks for none' do
        apply_entries({ 'view' => { 'render_as' => 'linked' } }, {})

        expect(config.index_fields['shelf_mark_tesim'].helper_method).to be_nil
      end

      it 'stops reading labels when the second is not controlled' do
        apply_entries(controlled, {})

        expect(config.index_fields['shelf_mark_tesim'].values).to be_nil
      end

      it 'lists the id facet again when the second is not controlled' do
        apply_entries(controlled, {})

        expect(config.facet_fields['shelf_mark_sim'].if).not_to be false
      end

      it "restores the application's own predicate on the id facet" do
        config.add_facet_field('shelf_mark_sim', label: 'Shelf Mark', if: :render_optionally?)

        apply_entries(controlled, {})

        expect(config.facet_fields['shelf_mark_sim'].if).to eq :render_optionally?
      end

      it 'lists a facet the first hid for its link when the second asks for the sidebar' do
        apply_entries(link_only, {})

        expect(config.facet_fields['shelf_mark_sim'].if).not_to be false
      end

      it 'drops the link facet the first registered when the second links to the other one' do
        apply_entries(link_only.merge(controlled), link_only)

        expect(config.facet_fields).not_to include('shelf_mark_label_sim')
      end

      it 'drops the link facet the first registered when the second neither facets nor links' do
        apply_entries(link_only, { 'indexing' => %w[shelf_mark_sim shelf_mark_tesim stored_searchable] })

        expect(config.facet_fields).not_to include('shelf_mark_sim')
      end

      it 'drops the label link facet the first registered when the second neither facets nor links' do
        apply_entries(link_only.merge(controlled), { 'indexing' => %w[shelf_mark_sim shelf_mark_tesim stored_searchable] })

        expect(config.facet_fields).not_to include('shelf_mark_label_sim')
      end

      it 'stops linking the row when the second neither facets nor links' do
        apply_entries(link_only, { 'indexing' => %w[shelf_mark_sim shelf_mark_tesim stored_searchable] })

        expect(config.index_fields['shelf_mark_tesim'].link_to_facet).to be_blank
      end

      it 'lists a label facet the first hid for its link when the second asks for the sidebar' do
        apply_entries(link_only.merge(controlled), controlled)

        expect(config.facet_fields['shelf_mark_label_sim'].if).not_to be false
      end

      context 'when the application configured the field' do
        before { config.add_index_field('shelf_mark_tesim', label: 'Shelf Mark') }

        it 'clears a link helper the first set when the second asks for none' do
          apply_entries({ 'view' => { 'render_as' => 'linked' } }, {})

          expect(config.index_fields['shelf_mark_tesim'].helper_method).to be_nil
        end

        it "replaces a link helper the first set with the second's" do
          apply_entries({ 'view' => { 'render_as' => 'linked' } }, { 'view' => { 'render_as' => 'external_link' } })

          expect(config.index_fields['shelf_mark_tesim'].helper_method).to eq :iconify_auto_link
        end
      end
    end

    it "keeps the settings of a retired surrogate's target that a current property still uses" do
      config.add_index_field('resource_type_tesim', label: 'Resource Type', helper_method: :an_application_helper)

      builder.apply(with_properties('monograph_resource_type' => resource_type.merge('name' => 'resource_type')), profile)

      expect(config.index_fields['resource_type_tesim'].helper_method).to eq :an_application_helper
    end

    it 'keeps the settings of a field a dropped property shared with a current one' do
      config.add_index_field('resource_type_tesim', label: 'Resource Type', helper_method: :an_application_helper)

      builder.apply(with_properties('monograph_resource_type' => { 'indexing' => %w[resource_type_sim resource_type_tesim] }), profile)

      expect(config.index_fields['resource_type_tesim'].helper_method).to eq :an_application_helper
    end
  end
end
