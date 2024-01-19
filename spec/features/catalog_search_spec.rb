# frozen_string_literal: true
RSpec.describe 'catalog searching', type: :feature do
  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    sign_in :user
    visit '/'
  end

  context 'with works and collections' do
    let!(:jills_work) do
      FactoryBot.valkyrie_create(:monograph, :public, title: ["Jill's Research"], keyword: ['jills_keyword', 'shared_keyword'])
    end

    let!(:jacks_work) do
      FactoryBot.valkyrie_create(:monograph, :public, title: ["Jack's Research"], keyword: ['jacks_keyword', 'shared_keyword'])
    end

    let!(:collection) do
      FactoryBot.valkyrie_create(:collection_resource, :public, keyword: ['collection_keyword', 'shared_keyword'])
    end

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

  context 'with public works and private collections', clean_repo: true do
    let!(:collection) do
      FactoryBot.valkyrie_create(:collection_resource, members: [jills_work])
    end

    let!(:jills_work) do
      FactoryBot.valkyrie_create(:monograph, :public, title: ["Jill's Research"], keyword: ['jills_keyword'])
    end

    it "hides collection facet values the user doesn't have access to view when performing a search" do
      within('#search-form-header') do
        fill_in('search-field-header', with: 'jills_keyword')
        click_button('Go')
      end

      expect(page).to have_content('Search Results')
      expect(page).to have_content(jills_work.title.first)
      expect(page).not_to have_content(collection.title.first)
      expect(page).not_to have_css('.blacklight-member_of_collection_ids_ssim')
    end

    context 'as an admin' do
      let(:admin_user) { create :admin }

      before do
        sign_in admin_user
        visit '/'
      end

      it "shows collection facet values the user has access to view when performing a search" do
        within('#search-form-header') do
          fill_in('search-field-header', with: 'jills_keyword')
          click_button('Go')
        end

        expect(page).to have_content('Search Results')
        expect(page).to have_content(jills_work.title.first)
        find('.blacklight-member_of_collection_ids_ssim').click
        expect(page).to have_content(collection.title.first)
      end
    end
  end
end
