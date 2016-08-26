require 'spec_helper'

describe 'curation_concerns/file_sets/_show_actions.html.erb', type: :view do
  let(:user) { create(:user) }
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { ['Frodo'] }
  let(:creator)     { ['Bilbo'] }
  let(:solr_document) {
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['FileSet'],
      human_readable_type_tesim: ['File'],
      contributor_tesim: contributor,
      creator_tesim: creator,
      rights_tesim: ['http://creativecommons.org/licenses/by/3.0/us/']
    )
  }
  let(:ability) { Ability.new(user) }
  let(:presenter) do
    Sufia::WorkShowPresenter.new(solr_document, ability)
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }
  describe 'citations' do
    before do
      Sufia.config.citations = citations
      allow(controller).to receive(:can?).with(:edit, presenter).and_return(false)
      assign(:presenter, presenter)
      view.lookup_context.view_paths.push 'app/views/curation_concerns/base'
      render
    end

    context 'when enabled' do
      let(:citations) { true }

      it 'appears on page' do
        expect(page).to have_selector('a#citations', count: 1)
      end
    end

    context 'when disabled' do
      let(:citations) { false }

      it 'does not appear on page' do
        expect(page).to have_no_selector('a#citations')
      end
    end
  end

  describe 'editor' do
    before do
      allow(presenter).to receive(:editor?).and_return(true)
      assign(:presenter, presenter)
      view.lookup_context.view_paths.push 'app/views/curation_concerns/base'
      render
    end

    it 'renders actions for the user' do
      expect(page).to have_link("Edit This File")
      expect(page).to have_link("Delete This File")
      expect(page).to have_link("Single-Use Link to File")
    end
  end
end
