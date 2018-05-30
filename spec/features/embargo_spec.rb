RSpec.describe 'embargo' do
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

  describe 'updating embargoed object' do
    let(:my_admin_set) do
      create(:admin_set,
             title: ['admin set with embargo range'],
             with_permission_template: { release_period: "6mos", with_active_workflow: true })
    end
    let(:default_admin_set) do
      create(:admin_set, id: AdminSet::DEFAULT_ID,
                         title: ["Default Admin Set"],
                         description: ["A description"],
                         with_permission_template: {})
    end
    let(:future_date) { 5.days.from_now }
    let(:later_future_date) { 10.days.from_now }
    let(:invalid_future_date) { 185.days.from_now } # More than 6 months
    let(:admin) { create(:admin) }
    let(:work) do
      create(:work, title: ['embargoed work1'],
                    embargo_release_date: future_date.to_datetime.iso8601,
                    admin_set_id: my_admin_set.id,
                    edit_users: [user])
    end

    it 'can be updated with a valid date' do
      visit "/concern/generic_works/#{work.id}"

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('This Generic Work is under embargo.')
      expect(page).to have_xpath("//input[@name='generic_work[embargo_release_date]' and @value='#{future_date.to_datetime.iso8601}']") # current embargo date is pre-populated in edit field

      fill_in 'until', with: later_future_date.to_s

      click_button 'Update Embargo'
      expect(page).to have_content(later_future_date.to_date.to_formatted_s(:standard))
      expect(page).to have_content(my_admin_set.title.first)
    end

    it 'cannot be updated with an invalid date' do
      visit "/concern/generic_works/#{work.id}"

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('This Generic Work is under embargo.')
      expect(page).to have_xpath("//input[@name='generic_work[embargo_release_date]' and @value='#{future_date.to_datetime.iso8601}']") # current embargo date is pre-populated in edit field

      fill_in 'until', with: invalid_future_date.to_s

      click_button 'Update Embargo'
      expect(page).to have_content('Release date specified does not match permission template release requirements for selected AdminSet.')
    end
  end
end
