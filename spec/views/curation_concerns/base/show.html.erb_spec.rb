require 'spec_helper'

describe 'curation_concerns/base/show.html.erb' do
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { 'Frodo' }
  let(:creator)     { 'Bilbo' }
  let(:solr_document) {
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['GenericWork'],
      human_readable_type_tesim: ['Generic Work'],
      contributor_tesim: contributor,
      creator_tesim: creator,
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
end
