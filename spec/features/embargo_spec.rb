RSpec.feature 'embargo' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end
  describe 'creating an embargoed object' do
    let(:future_date) { 5.days.from_now }
    let(:later_future_date) { 10.days.from_now }

    it 'can be created, displayed and updated', :clean_repo, :workflow do
      visit '/concern/generic_works/new'
      fill_in 'Title', with: 'Embargo test'
      choose 'Embargo'
      fill_in 'generic_work_embargo_release_date', with: future_date
      select 'Private', from: 'Restricted to'
      select 'Public', from: 'then open it up to'
      click_button 'Save'

      # chosen embargo date is on the show page
      expect(page).to have_content(future_date.to_date.to_formatted_s(:standard))

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('This Generic Work is under embargo.')
      expect(page).to have_xpath("//input[@name='generic_work[embargo_release_date]' and @value='#{future_date.to_datetime.iso8601}']") # current embargo date is pre-populated in edit field

      fill_in 'until', with: later_future_date.to_s

      click_button 'Update Embargo'
      expect(page).to have_content(later_future_date.to_date.to_formatted_s(:standard))
    end
  end

  describe 'managing embargoes' do
    let(:user) { create(:user, groups: ['admin']) }

    it 'shows lists of objects under lease' do
      visit '/embargoes'
      expect(page).to have_content 'Manage Embargoes'
    end
  end
end
