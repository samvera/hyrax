# frozen_string_literal: true
RSpec.describe 'hyrax/base/_citations.html.erb', type: :view do
  let(:user) { create(:user) }
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:contributor) { ['Frodo'] }
  let(:creator)     { ['Bilbo'] }
  let(:solr_document) do
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['GenericWork'],
      human_readable_type_tesim: ['Generic Work'],
      contributor_tesim: contributor,
      creator_tesim: creator,
      rights_tesim: ['http://creativecommons.org/licenses/by/3.0/us/']
    )
  end
  let(:ability) { Ability.new(user) }
  let(:presenter) do
    Hyrax::WorkShowPresenter.new(solr_document, ability)
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    Hyrax.config.citations = citations
    allow(controller).to receive(:can?).with(:edit, presenter).and_return(false)
    render 'hyrax/base/citations', presenter: presenter
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
