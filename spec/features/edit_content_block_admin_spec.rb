# frozen_string_literal: true
RSpec.describe 'Editing content blocks as admin', :js do
  let(:user) { create(:admin) }

  context 'when user wants to change tabs' do
    let!(:confirm_modal_text) { 'Are you sure you want to leave this tab? Any unsaved data will be lost.' }

    before do
      allow(Hyrax::Statistic).to receive(:work_types).and_return([])
      sign_in user
      visit '/dashboard'
      click_link 'Settings'
      click_link 'Content Blocks'
    end

    it "does not display a confirmation message when form data has not changed" do
      expect(page).to have_content('Content Blocks')
      expect(page).to have_content('Announcement')
      find('#marketing-nav-item').click
      expect(page).not_to have_content(confirm_modal_text)
    end

    it "displays a confirmation message when form data has changed" do
      expect(page).to have_content('Content Blocks')
      expect(page).to have_content('Announcement')
      expect(page).to have_selector('#content_block_announcement_ifr')
      within_frame('content_block_announcement_ifr') do
        find('body').set('Updated text.')
      end
      find('#marketing-nav-item').click
      within('#nav-safety-modal') do
        expect(page).to have_content(confirm_modal_text)
      end
    end

    it "change tab when user dismisses the confirmation" do
      expect(page).to have_selector('#announcement_text', class: 'active')
      expect(page).not_to have_selector('#marketing', class: 'active')
      within_frame('content_block_announcement_ifr') do
        find('body').set('Updated text.')
      end
      find('#marketing-nav-item').click
      within('#nav-safety-modal') do
        click_button('OK')
      end
      expect(page).to have_selector('#marketing', class: 'active')
      expect(page).not_to have_selector('#announcement_text', class: 'active')
    end

    it "does not redisplay the confirmation unless form data is changed" do
      expect(page).to have_selector('#announcement_text', class: 'active')
      expect(page).not_to have_selector('#marketing', class: 'active')
      within_frame('content_block_announcement_ifr') do
        find('body').set('Updated text.')
      end
      find('#marketing-nav-item').click
      within('#nav-safety-modal') do
        click_button('OK')
      end
      find('#marketing-nav-item').click
      expect(page).not_to have_content(confirm_modal_text)
    end
  end
end
