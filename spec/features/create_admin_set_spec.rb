# frozen_string_literal: true
RSpec.describe 'Creating a new Admin Set', :js, :workflow, :clean_repo do
  include Selectors::Dashboard

  let(:admin)   { create(:admin, email: 'admin@example.com') }
  let(:manager) { create(:user, email: 'manager@example.com') }
  let(:creator) { create(:user, email: 'creator@example.com') }
  let(:viewer)  { create(:user, email: 'viewer@example.com') }
  let(:user)    { create(:user, email: 'user@example.com') }

  # make sure all users can create at least 2 collection types (user and other)
  let!(:user_collection_type) { FactoryBot.create(:user_collection_type) }
  let!(:other_collection_type) do
    FactoryBot.create(:collection_type,
                      title: "Other",
                      creator_user: [manager.user_key, creator.user_key, user.user_key])
  end
  let!(:admin_set_type) do
    FactoryBot.create(:admin_set_collection_type,
                      manager_user: manager.user_key, creator_user: creator.user_key)
  end

  context "when the user is not an admin" do
    context "and user does not have permissions to create admin sets" do
      before do
        sign_in user
        click_link 'Collections'
      end

      it 'user is not offered the option to create an admin set' do
        # try and create the new admin set
        click_button "New Collection"
        expect(page).to have_xpath("//h4", text: "User Collection")
        expect(page).to have_xpath("//h4", text: "Other")
        expect(page).not_to have_xpath("//h4", text: "Admin Set")
      end
    end

    context "and has permissions to create admin sets" do
      before do
        sign_in creator
        click_link 'Collections'
      end

      it 'creates the admin set' do
        # create the new admin set
        click_button "New Collection"
        expect(page).to have_xpath("//h4", text: "User Collection")
        expect(page).to have_xpath("//h4", text: "Other")
        expect(page).to have_xpath("//h4", text: "Admin Set")
        choose "collection_type", option: "AdminSet"
        click_button 'Create collection'
        fill_in('Title', with: 'An Admin Set')
        click_on('Save')
        expect(page).to have_content("The administrative set 'An Admin Set' has been created. Use the additional tabs to define other aspects of the administrative set.")

        # add viewer
        click_link('Participants')
        expect(page).to have_selector(".form-inline.add-users .select2-container")
        select_user_for_admin_set(viewer, 'Viewer')
        expect(page).to have_selector('td', text: viewer.user_key)

        # navigate to show page for the new admin set
        visit '/dashboard'
        click_on('Collections')
        click_on('Display all details of An Admin Set')

        # confirm creating user can view and edit the new admin set
        expect(page).to have_xpath('//h2', text: 'An Admin Set')
        creator_entity = page.find(:xpath, "//div//dt", text: "Creator")
                             .first(:xpath, ".//..//dd")
                             .first(:xpath, ".//a")
        expect(creator_entity.text).to eq creator.user_key
        expect(page).to have_link('Edit')

        # confirm admin can view and edit the new admin set
        logout
        sign_in admin
        click_link 'Collections'
        click_link 'All Collections'
        click_on('Display all details of An Admin Set')
        expect(page).to have_xpath('//h2', text: 'An Admin Set')
        creator_entity = page.find(:xpath, "//div//dt", text: "Creator")
                             .first(:xpath, ".//..//dd")
                             .first(:xpath, ".//a")
        expect(creator_entity.text).to eq creator.user_key
        expect(page).to have_link('Edit')

        # confirm a collection type manager can view and edit the new admin set
        logout
        sign_in manager
        click_link 'Collections'
        click_link 'Managed Collections'
        click_on('Display all details of An Admin Set')
        expect(page).to have_xpath('//h2', text: 'An Admin Set')
        creator_entity = page.find(:xpath, "//div//dt", text: "Creator")
                             .first(:xpath, ".//..//dd")
                             .first(:xpath, ".//a")
        expect(creator_entity.text).to eq creator.user_key
        expect(page).to have_link('Edit')

        # confirm a viewer can view, but not edit the new admin set
        logout
        sign_in viewer
        click_link 'Collections'
        click_link 'Managed Collections'
        click_on('Display all details of An Admin Set')
        expect(page).to have_xpath('//h2', text: 'An Admin Set')
        creator_entity = page.find(:xpath, "//div//dt", text: "Creator")
                             .first(:xpath, ".//..//dd")
                             .first(:xpath, ".//a")
        expect(creator_entity.text).to eq creator.user_key
        expect(page).not_to have_link('Edit')

        view_path = page.current_path
        edit_path = view_path + '/edit'

        # confirm registered user without special access cannot view or edit even if they know the links
        visit '/'
        logout
        sign_in user
        visit view_path
        expect(page.current_path).to eq '/'
        expect(page).to have_content("You are not authorized to access this page.")
        visit edit_path
        expect(page.current_path).to eq '/'
        expect(page).to have_content("You are not authorized to access this page.")

        # confirm guest user cannot view or edit even if they know the links
        visit '/'
        logout
        visit view_path
        expect(page.current_path).to eq '/users/sign_in'
        visit edit_path
        expect(page.current_path).to eq '/users/sign_in'
      end
    end

    context "and has permissions to manage admin sets" do
      before do
        sign_in manager
        click_link 'Collections'
      end

      it 'creates the admin set' do
        # create the new admin set
        click_button "New Collection"
        expect(page).to have_xpath("//h4", text: "User Collection")
        expect(page).to have_xpath("//h4", text: "Other")
        expect(page).to have_xpath("//h4", text: "Admin Set")
        choose "collection_type", option: "AdminSet"
        click_button 'Create collection'
        fill_in('Title', with: 'An Admin Set')
        click_on('Save')
        expect(page).to have_content("The administrative set 'An Admin Set' has been created. Use the additional tabs to define other aspects of the administrative set.")

        # navigate to show page for the new admin set
        visit '/dashboard'
        click_on('Collections')
        click_on('Display all details of An Admin Set')

        # confirm creating user can view and edit the new admin set
        expect(page).to have_xpath('//h2', text: 'An Admin Set')
        creator_entity = page.find(:xpath, "//div//dt", text: "Creator")
                             .first(:xpath, ".//..//dd")
                             .first(:xpath, ".//a")
        expect(creator_entity.text).to eq manager.user_key
        expect(page).to have_link('Edit')

        # confirm admin can view and edit the new admin set
        logout
        sign_in admin
        click_link 'Collections'
        click_link 'All Collections'
        click_on('Display all details of An Admin Set')
        expect(page).to have_xpath('//h2', text: 'An Admin Set')
        creator_entity = page.find(:xpath, "//div//dt", text: "Creator")
                             .first(:xpath, ".//..//dd")
                             .first(:xpath, ".//a")
        expect(creator_entity.text).to eq manager.user_key
        expect(page).to have_link('Edit')

        # confirm a collection type creator can not view the new admin set
        logout
        sign_in creator
        click_link 'Collections'
        expect(page).not_to have_content('Managed Collections')
        expect(page).not_to have_content('An Admin Set')
      end
    end
  end

  context "when user is an admin" do
    let(:admin) { FactoryBot.create(:admin) }

    before do
      sign_in admin
      click_link 'Collections'
    end

    it 'creates the admin set' do
      # create the new admin set
      click_button "New Collection"
      expect(page).to have_xpath("//h4", text: "User Collection")
      expect(page).to have_xpath("//h4", text: "Other")
      expect(page).to have_xpath("//h4", text: "Admin Set")
      choose "collection_type", option: "AdminSet"
      click_button 'Create collection'
      fill_in('Title', with: 'An Admin Set')
      click_on('Save')
      expect(page).to have_content("The administrative set 'An Admin Set' has been created. Use the additional tabs to define other aspects of the administrative set.")

      # navigate to show page for the new admin set
      visit '/dashboard'
      click_on('Collections')
      click_on('Display all details of An Admin Set')

      # confirm creating user can view and edit the new admin set
      expect(page).to have_xpath('//h2', text: 'An Admin Set')
      creator = page.find(:xpath, "//div//dt", text: "Creator")
                    .first(:xpath, ".//..//dd")
                    .first(:xpath, ".//a")
      expect(creator.text).to eq admin.user_key
      expect(page).to have_link('Edit')

      # confirm a collection type manager can view and edit the new admin set
      logout
      sign_in manager
      click_link 'Collections'
      click_link 'Managed Collections'
      click_on('Display all details of An Admin Set')
      expect(page).to have_xpath('//h2', text: 'An Admin Set')
      creator_entity = page.find(:xpath, "//div//dt", text: "Creator")
                           .first(:xpath, ".//..//dd")
                           .first(:xpath, ".//a")
      expect(creator_entity.text).to eq admin.user_key
      expect(page).to have_link('Edit')

      # confirm a collection type creator can not view the new admin set
      logout
      sign_in creator
      click_link 'Collections'
      expect(page).not_to have_content('Managed Collections')
      expect(page).not_to have_content('An Admin Set')
    end
  end
end
