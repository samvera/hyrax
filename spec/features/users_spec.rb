describe "User Profile", type: :feature do
  before do
    sign_in user
  end
  let(:user) { create(:user) }
  let(:profile_path) { Sufia::Engine.routes.url_helpers.profile_path(user) }

  context 'when visiting user profile' do
    it 'renders page properly' do
      visit profile_path
      expect(page).to have_content(user.email)
      expect(page).to have_content('Edit Your Profile')
    end
  end

  context 'when clicking all users' do
    # TODO: Move this to a view test
    it 'displays all users' do
      visit profile_path
      click_link 'View Users'
      expect(page).to have_xpath("//td/a[@href='#{profile_path}']")
    end
  end

  context 'when visiting user profile' do
    it 'page should be editable' do
      visit profile_path
      click_link 'Edit Your Profile'
      fill_in 'user_twitter_handle', with: 'curatorOfData'
      click_button 'Save Profile'
      expect(page).to have_content 'Your profile has been updated'
      expect(page).to have_link('curatorOfData', href: 'http://twitter.com/curatorOfData')
    end
  end

  context 'user profile' do
    let!(:dewey) { create(:user, display_name: 'Melvil Dewey') }
    let(:dewey_path) { Sufia::Engine.routes.url_helpers.profile_path(dewey) }

    it 'is searchable' do
      visit profile_path
      click_link 'View Users'
      expect(page).to have_xpath("//td/a[@href='#{profile_path}']")
      expect(page).to have_xpath("//td/a[@href='#{dewey_path}']")
      fill_in 'user_search', with: 'Dewey'
      click_button "user_submit"
      expect(page).to_not have_xpath("//td/a[@href='#{profile_path}']")
      expect(page).to have_xpath("//td/a[@href='#{dewey_path}']")
    end
  end
end
