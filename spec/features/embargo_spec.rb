# frozen_string_literal: true
RSpec.describe 'embargo' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end
  describe 'creating an embargoed object' do
    let(:future_date) { Time.zone.today + 5 }
    let(:later_future_date) { Time.zone.today + 10 }

    it 'can be created, displayed and updated', :clean_repo, :workflow do
      visit '/concern/generic_works/new'
      fill_in 'Title', with: 'Embargo test'
      choose 'Embargo'
      fill_in 'generic_work_embargo_release_date', with: future_date
      select 'Private', from: 'Restricted to'
      select 'Public', from: 'then open it up to'
      click_button 'Save'

      # chosen embargo date is on the show page
      expect(page).to have_content(future_date.to_formatted_s(:standard))

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('This Generic Work is under embargo.')
      expect(page).to have_xpath("//input[@name='generic_work[embargo_release_date]' and @value='#{future_date}']") # current embargo date is pre-populated in edit field

      fill_in 'until', with: later_future_date.to_s

      click_button 'Update Embargo'
      expect(page).to have_content(later_future_date.to_formatted_s(:standard))

      click_link 'Edit'
      fill_in 'Title', with: 'Embargo test CHANGED'
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
    let(:future_date) { Time.zone.today + 5 }
    let(:later_future_date) { Time.zone.today + 10 }
    let(:invalid_future_date) { Time.zone.today + 185 } # More than 6 months
    let(:admin) { create(:admin) }
    let(:work) do
      create(:work, title: ['embargoed work1'],
                    embargo_release_date: future_date,
                    visibility_after_embargo: 'open',
                    visibility_during_embargo: 'restricted',
                    admin_set_id: my_admin_set.id,
                    edit_users: [user])
    end

    it 'can be updated with a valid date' do
      visit "/concern/generic_works/#{work.id}"

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('This Generic Work is under embargo.')
      expect(page).to have_xpath("//input[@name='generic_work[embargo_release_date]' and @value='#{future_date}']") # current embargo date is pre-populated in edit field

      fill_in 'until', with: later_future_date.to_s

      click_button 'Update Embargo'
      expect(page).to have_content(later_future_date.to_formatted_s(:standard))
      expect(page).to have_content(my_admin_set.title.first)
    end

    it 'cannot be updated with an invalid date' do
      visit "/concern/generic_works/#{work.id}"

      click_link 'Edit'
      click_link 'Embargo Management Page'

      expect(page).to have_content('This Generic Work is under embargo.')
      expect(page).to have_xpath("//input[@name='generic_work[embargo_release_date]' and @value='#{future_date}']") # current embargo date is pre-populated in edit field

      fill_in 'until', with: invalid_future_date.to_s

      click_button 'Update Embargo'
      expect(page).to have_content('Release date specified does not match permission template release requirements for selected AdminSet.')
    end
  end
end
