# frozen_string_literal: true
RSpec.describe 'leases' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end
  describe 'create a new leased object' do
    let(:future_date) { Time.zone.today + 5 }
    let(:later_future_date) { Time.zone.today + 10 }

    it 'can be created, displayed and updated', :clean_repo, :workflow do
      visit '/concern/generic_works/new'
      fill_in 'Title', with: 'Lease test'
      fill_in 'Creator', with: 'Doe, Jane'
      choose 'Lease'
      fill_in 'generic_work_lease_expiration_date', with: future_date
      select 'Public', from: 'Is available to'
      select 'Private', from: 'then restrict it to'
      click_button 'Save'

      # chosen lease date is on the show page
      expect(page).to have_content(future_date.to_formatted_s(:standard))

      click_link 'Edit'
      click_link 'Lease Management Page'

      expect(page).to have_content('This Generic Work is under lease.')
      expect(page).to have_xpath("//input[@name='generic_work[lease_expiration_date]' and @value='#{future_date}']") # current lease date is pre-populated in edit field

      fill_in 'until', with: later_future_date.to_s

      click_button 'Update Lease'
      expect(page).to have_content(later_future_date.to_formatted_s(:standard)) # new lease date is displayed in message

      click_link 'Edit'
      fill_in 'Title', with: 'Lease test CHANGED'
      click_button 'Save'

      expect(page).to have_content('CHANGED')

      click_link 'Edit'
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('div#add-files') do
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
      end

      click_button 'Save' # Save the work
      expect(page).to have_content('CHANGED')
    end
  end
end
