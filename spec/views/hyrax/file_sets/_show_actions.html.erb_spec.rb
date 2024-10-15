# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_show_actions.html.erb', type: :view do
  let(:user) { create(:user) }
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { ['Frodo'] }
  let(:creator)     { ['Bilbo'] }
  let(:solr_document) do
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['FileSet'],
      human_readable_type_tesim: ['File'],
      contributor_tesim: contributor,
      creator_tesim: creator,
      rights_tesim: ['http://creativecommons.org/licenses/by/3.0/us/']
    )
  end
  let(:decorated_solr_document) { Hyrax::SolrDocument::OrderedMembers.decorate(solr_document) }
  let(:ability) { Ability.new(user) }
  let(:presenter) do
    Hyrax::WorkShowPresenter.new(solr_document, ability)
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }
  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(controller).to receive(:controller_name).and_return('file_sets')
  end

  describe 'citations' do
    before do
      Hyrax.config.citations = citations
      allow(ability).to receive(:can?).with(:edit, anything).and_return(false)
      assign(:presenter, presenter)
      stub_template '_social_media.html.erb' => 'social_media'
      render
    end

    context 'when enabled' do
      let(:citations) { true }

      it 'does not appear on page' do
        expect(page).to have_no_selector('a#citations')
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
      allow(ability).to receive(:can?).with(:edit, anything).and_return(true)
      allow(presenter).to receive(:editor?).and_return(true)
      assign(:presenter, presenter)
      stub_template '_social_media.html.erb' => 'social_media'
      render
    end

    it 'renders actions for the user' do
      expect(page).to have_link("Edit This File")
      expect(page).to have_link("Delete This File")
    end
  end
end
