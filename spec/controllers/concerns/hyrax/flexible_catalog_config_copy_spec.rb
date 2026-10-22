# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Controllers that copy the catalog config' do
  let(:profile) do
    YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')).deep_merge(YAML.safe_load(<<-YAML))
      properties:
        resource_type:
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
  let(:label_service) do
    Class.new(Hyrax::ControlledVocabularyLabelService) do
      def resolvable?(source)
        source == 'resource_types'
      end
    end.new
  end
  let(:catalog) do
    Class.new(ApplicationController) do
      include Blacklight::Configurable
      include Hyrax::FlexibleCatalogBehavior

      configure_blacklight do |config|
        config.add_search_field('all_fields') { |field| field.solr_parameters = { qf: String.new('') } }
      end
    end
  end
  let(:flexible) { true }

  before do
    stub_const('CatalogController', catalog)
    allow(Hyrax.config).to receive_messages(flexible?: flexible, controlled_vocabulary_label_service: label_service)
    allow(Hyrax::FlexibleSchema).to receive_message_chain(:order, :last).with('created_at asc').with(2)
                                                                     .and_return([double('FlexibleSchema', profile:)])
  end

  [Hyrax::FileSetsController, Hyrax::CollectionsController, Hyrax::SingleUseLinksViewerController].each do |controller_class|
    describe controller_class do
      let(:config) { controller_class.new.blacklight_config }

      before { allow(controller_class).to receive(:blacklight_config).and_return(Blacklight::Configuration.new) }

      it "facets a controlled property on its labels, from the catalog's profile-driven config" do
        expect(config.facet_fields).to include('resource_type_label_sim')
      end

      it 'has the same search result fields as the catalog' do
        CatalogController.load_flexible_schema

        expect(config.index_fields.keys).to include('title_tesim')
        expect(config.index_fields.keys).to eq CatalogController.blacklight_config.index_fields.keys
      end

      it "answers the catalog's display condition for those fields" do
        field = config.index_fields.values.find { |index_field| index_field.if == :render_optionally? }

        expect(field).to be_present
        expect(Blacklight::Configuration::Context.new(controller_class.new).evaluate_if_unless_configuration(field, SolrDocument.new)).to be true
      end

      context "with an application's own render_optionally?" do
        let(:catalog) do
          super().tap do |klass|
            klass.define_method(:render_optionally?) do |field_config, _document|
              field_config.key != 'abstract_tesim' && request.path == '/page'
            end
          end
        end
        let(:page) { controller_class.new.tap { |controller| controller.request = ActionDispatch::TestRequest.create('PATH_INFO' => '/page') } }

        def shown?(field_name)
          Blacklight::Configuration::Context.new(page).evaluate_if_unless_configuration(page.blacklight_config.index_fields[field_name], SolrDocument.new)
        end

        it 'hides a field the override hides' do
          expect(shown?('abstract_tesim')).to be false
        end

        it "shows a field the override shows, judged against the page's request" do
          expect(shown?('title_tesim')).to be true
        end
      end

      context 'when flexible metadata is off' do
        let(:flexible) { false }

        it 'keeps the config the controller copied' do
          expect(config.facet_fields).to be_empty
        end
      end
    end
  end

  describe 'a work controller' do
    let(:config) { Hyrax::GenericWorksController.new.blacklight_config }

    before { allow(Hyrax::GenericWorksController).to receive(:blacklight_config).and_return(Blacklight::Configuration.new) }

    it "facets a controlled property on its labels, from the catalog's profile-driven config" do
      expect(config.facet_fields).to include('resource_type_label_sim')
    end
  end

  it "keeps the file set controller's own search builder" do
    expect(Hyrax::FileSetsController.new.blacklight_config.search_builder_class).to eq Hyrax::FileSetSearchBuilder
  end

  it 'leaves the admin set dashboard on the config it copied' do
    allow(Hyrax::Admin::AdminSetsController).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)

    expect(Hyrax::Admin::AdminSetsController.new.blacklight_config.facet_fields).to be_empty
  end
end

RSpec.describe Hyrax::CollectionsController, '#search_action_path', type: :controller do
  routes { Hyrax::Engine.routes }

  before do
    controller.request.path_parameters = { controller: 'hyrax/collections', action: 'show', id: 'abc-123' }
  end

  it "links a collection page's facet values to the catalog search" do
    path = URI(controller.send(:search_action_path, f: { resource_type_label_sim: ['Still image'] }))

    expect(path.path).to eq '/catalog'
    expect(Rack::Utils.parse_nested_query(path.query)).to include('f' => { 'resource_type_label_sim' => ['Still image'] })
  end
end
