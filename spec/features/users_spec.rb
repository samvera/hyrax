# frozen_string_literal: true
RSpec.describe "User Profile", type: :feature do
  before do
    sign_in user
  end
  let(:user) { create(:user) }
  let(:profile_path) { Hyrax::Engine.routes.url_helpers.user_path(user, locale: 'en') }

  context 'when visiting user profile with highlighted works' do
    let(:work) { valkyrie_create(:monograph, title: 'Test Monograph 123', depositor: user.user_key) }

    before do
      user.trophies.create!(work_id: work.id)
    end

    it 'page should be editable' do
      visit profile_path
      expect(page).to have_content(user.email)

      within '.highlighted-works' do
        expect(page).to have_link('Test Monograph 123', href: "/concern/monographs/#{work.id}?locale=en")
      end

      within '.panel-user' do
        click_link 'Edit Profile'
      end
      fill_in 'user_twitter_handle', with: 'curatorOfData'
      click_button 'Save Profile'
      expect(page).to have_content 'Your profile has been updated'
      expect(page).to have_link('curatorOfData', href: 'http://twitter.com/curatorOfData')
    end
  end

  context 'user profile' do
    let!(:dewey) { create(:user, display_name: 'Melvil Dewey') }
    let(:dewey_path) { Hyrax::Engine.routes.url_helpers.user_path(dewey, locale: 'en') }

    it 'is searchable' do
      visit profile_path
      click_link 'View Users'
      expect(page).to have_xpath("//td/a[@href='#{profile_path}']")
      expect(page).to have_xpath("//td/a[@href='#{dewey_path}']")
      fill_in 'user_search', with: 'Dewey'
      click_button "user_submit"
      expect(page).not_to have_xpath("//td/a[@href='#{profile_path}']")
      expect(page).to have_xpath("//td/a[@href='#{dewey_path}']")
    end
  end
end
