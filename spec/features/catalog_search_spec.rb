require 'spec_helper'

describe 'catalog searching', type: :feature do
  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    sign_in :user
    visit '/'
  end

  context 'with works and collections' do
    let!(:jills_work) do
      create(:public_work, title: ["Jill's Research"], tag: ['jills_tag', 'shared_tag'])
    end

    let!(:jacks_work) do
      create(:public_work, title: ["Jack's Research"], tag: ['jacks_tag', 'shared_tag'])
    end

    let!(:collection) { create(:public_collection, tag: ['collection_tag', 'shared_tag']) }

    it 'performing a search' do
      within('#search-form-header') do
        fill_in('search-field-header', with: 'shared_tag')
        click_button('Go')
      end

      expect(page).to have_content('Search Results')
      expect(page).to have_content(jills_work.title.first)
      expect(page).to have_content(jacks_work.title.first)
      expect(page).to have_content(collection.title.first)
    end
  end
end
