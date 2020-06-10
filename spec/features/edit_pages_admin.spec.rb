# frozen_string_literal: true
RSpec.describe 'Editing pages as admin', :js do
  let(:user) { create(:admin) }

  context 'when user wants to change tabs' do
    let!(:confirm_modal_text) { 'Are you sure you want to leave this tab? Any unsaved data will be lost.' }

    before do
      sign_in user
      visit '/dashboard'
      click_link 'Settings'
      click_link 'Pages'
    end

    it "does not display a confirmation message when form data has not changed" do
      expect(page).to have_content('Content Blocks')
      expect(page).to have_content('About')
      click_link 'Help Page'
      expect(page).not_to have_content(confirm_modal_text)
    end

    it "displays a confirmation message when form data has changed" do
      expect(page).to have_content('Content Blocks')
      expect(page).to have_content('About')
      expect(page).to have_selector('#content_block_about_ifr')
      within_frame('content_block_about_ifr') do
        find('body').set('Updated text.')
      end
      click_link 'Help Page'
      within('#nav-safety-modal') do
        expect(page).to have_content(confirm_modal_text)
      end
    end

    it "changes tab when user dismisses the confirmation by clicking OK" do
      expect(page).to have_selector('#about', class: 'active')
      expect(page).not_to have_selector('#help', class: 'active')
      within_frame('content_block_about_ifr') do
        find('body').set('Updated text.')
      end
      click_link 'Help Page'
      within('#nav-safety-modal') do
        click_button('OK')
      end
      expect(page).to have_selector('#help', class: 'active')
      expect(page).not_to have_selector('#about', class: 'active')
    end

    it "does not redisplay the confirmation unless form data is changed" do
      expect(page).to have_selector('#about', class: 'active')
      expect(page).not_to have_selector('#help', class: 'active')
      within_frame('content_block_about_ifr') do
        find('body').set('Updated text.')
      end
      click_link 'Help Page'
      within('#nav-safety-modal') do
        click_button('OK')
      end
      click_link 'Deposit Agreement'
      expect(page).not_to have_content(confirm_modal_text)
    end
  end
end
