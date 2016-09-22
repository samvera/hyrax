require 'spec_helper'

describe 'curation_concerns/base/show.html.erb' do
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { ['Frodo', 'Sam'] }
  let(:creator)     { 'Bilbo' }
  let(:solr_document) {
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['GenericWork'],
      human_readable_type_tesim: ['Generic Work'],
      contributor_tesim: contributor,
      creator_tesim: creator,
      language_tesim: 'Hobbish',
      rights_tesim: ['http://creativecommons.org/licenses/by/3.0/us/']
    )
  }

  let(:entity) { instance_double(Sipity::Entity, workflow_state_name: 'pending') }
  let(:ability) { nil }
  let(:presenter) do
    CurationConcerns::WorkShowPresenter.new(solr_document, ability)
  end

  before do
    allow(PowerConverter).to receive(:convert).and_return(entity)
  end

  context 'for editors' do
    before do
      allow(view).to receive(:can?).with(:edit, String).and_return(true)
      allow(view).to receive(:can?).with(:collect, String).and_return(true)
      allow(view).to receive(:collection_options_for_select)
      assign(:presenter, presenter)
      render
    end
    let(:header_node) do
      header_content = view.view_flow.content[:page_header]
      Capybara::Node::Simple.new(header_content)
    end

    it 'draws the page' do
      expect(header_node).to have_selector '.state.state-pending', text: 'pending'
      expect(rendered).to have_link 'Attribution 3.0 United States', href: 'http://creativecommons.org/licenses/by/3.0/us/'
      expect(rendered).to have_link 'Edit This Generic Work', href: edit_polymorphic_path(presenter)
    end
  end

  context 'with parent_presenter' do
    before do
      allow(view).to receive(:can?).with(:edit, String).and_return(true)
      allow(view).to receive(:can?).with(:collect, String).and_return(true)
      allow(view).to receive(:collection_options_for_select)
      assign(:presenter, presenter)
      assign(:parent_presenter, parent_presenter)
      allow(parent_presenter).to receive(:to_s).and_return("Parent Work")
      render
    end
    let(:parent_presenter) do
      CurationConcerns::WorkShowPresenter.new(solr_document, ability)
    end
    let(:header_node) do
      header_content = view.view_flow.content[:page_header]
      Capybara::Node::Simple.new(header_content)
    end

    it 'draws the page' do
      expect(header_node).to have_selector '.breadcrumb', text: 'Parent Work'
    end
  end

  context 'for non-editors' do
    before do
      assign(:presenter, presenter)
      allow(view).to receive(:can?).with(:edit, String).and_return(false)
      allow(view).to receive(:can?).with(:collect, String).and_return(false)
      render
    end
    it 'does not have links to edit' do
      expect(rendered).not_to have_content('Edit this Generic Work')
    end
  end

  describe 'schema.org' do
    before do
      assign(:presenter, presenter)
      allow(view).to receive(:can?).with(:edit, String).and_return(false)
      allow(view).to receive(:can?).with(:collect, String).and_return(false)
      render
    end
    let(:item) { Mida::Document.new("<html>#{rendered}</html>").items.first }
    describe 'descriptive metadata' do
      it 'draws schema.org fields' do
        # default itemtype to CreativeWork
        expect(item.type).to eq('http://schema.org/CreativeWork')

        contributors = item.properties['contributor']
        expect(contributors.count).to eq(2)
        contributor = contributors.last
        expect(contributor.type).to eq('http://schema.org/Person')
        expect(contributor.properties['name'].first).to eq('Sam')

        creators = item.properties['creator']
        expect(creators.count).to eq(1)
        creator = creators.first
        expect(creator.type).to eq('http://schema.org/Person')
        expect(creator.properties['name'].first).to eq('Bilbo')

        languages = item.properties['inLanguage']
        expect(languages.count).to eq(1)
        language = languages.first
        expect(language).to eq('Hobbish')
      end
    end
  end
end
