describe 'catalog searching', type: :feature do
  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    sign_in :user
    visit '/'
  end

  context 'with works and collections' do
    let!(:jills_work) do
      create(:public_work, title: ["Jill's Research"], keyword: ['jills_keyword', 'shared_keyword'])
    end

    let!(:jacks_work) do
      create(:public_work, title: ["Jack's Research"], keyword: ['jacks_keyword', 'shared_keyword'])
    end

    let!(:collection) { create(:public_collection, keyword: ['collection_keyword', 'shared_keyword']) }

    it 'performing a search' do
      within('#search-form-header') do
        fill_in('search-field-header', with: 'shared_keyword')
        click_button('Go')
      end

      expect(page).to have_content('Search Results')
      expect(page).to have_content(jills_work.title.first)
      expect(page).to have_content(jacks_work.title.first)
      expect(page).to have_content(collection.title.first)
    end
  end
end
