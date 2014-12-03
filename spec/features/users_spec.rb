require 'spec_helper'

describe "User Profile", :type => :feature do

  before do
    sign_in FactoryGirl.create(:curator)
  end

  context 'when visiting user profile' do
    it 'should render page properly' do
      visit '/users/curator1@example-dot-com'
      expect(page).to have_content('curator1@example.com')
      expect(page).to have_content('Edit Your Profile')
    end
  end

  context 'when clicking all users' do
    it 'should display all users' do
      visit '/users/curator1@example-dot-com'
      click_link 'View Users'
      expect(page).to have_xpath("//td/a[@href='/users/curator1@example-dot-com']")
    end
  end

  context 'when visiting user profile' do
    it 'page should be editable' do
      visit '/users/curator1@example-dot-com'
      click_link 'Edit Your Profile'
      fill_in 'user_twitter_handle', with: 'curatorOfData'
      click_button 'Save Profile'
      expect(page).to have_content 'Your profile has been updated'
      click_link 'Profile'
      expect(page).to have_link('curatorOfData', href: 'http://twitter.com/curatorOfData')
    end
  end

  context 'user profile' do
    it 'should be searchable' do
      @archivist = FactoryGirl.find_or_create(:archivist)
      visit '/users/curator1@example-dot-com'
      click_link 'View Users'
      expect(page).to have_xpath("//td/a[@href='/users/curator1@example-dot-com']")
      expect(page).to have_xpath("//td/a[@href='/users/archivist1@example-dot-com']")
      fill_in 'user_search', with: 'archivist1@example.com'
      click_button "user_submit"
      expect(page).to_not have_xpath("//td/a[@href='/users/curator1@example-dot-com']")
      expect(page).to have_xpath("//td/a[@href='/users/archivist1@example-dot-com']")
    end
  end
end
