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

  let(:ability) { nil }
  let(:presenter) do
    CurationConcerns::WorkShowPresenter.new(solr_document, ability)
  end

  context 'for editors' do
    before do
      allow(view).to receive(:can?).with(:edit, String).and_return(true)
      allow(view).to receive(:can?).with(:collect, String).and_return(true)
      assign(:presenter, presenter)
      render
    end

    it 'draws the page' do
      expect(rendered).to have_link 'Attribution 3.0 United States', href: 'http://creativecommons.org/licenses/by/3.0/us/'
      expect(rendered).to have_link 'Edit This Generic Work', href: edit_polymorphic_path(presenter)
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
