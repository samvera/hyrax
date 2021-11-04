# frozen_string_literal: true
RSpec.describe 'Creating a new Admin Set', :js, :workflow, :clean_repo do
  let(:admin) { create(:admin, email: 'admin@example.com') }
  let(:manager) { create(:user, email: 'manager@example.com') }
  let(:creator) { create(:user, email: 'creator@example.com') }
  let(:user) { create(:user, email: 'powerless@example.com') }

  # make sure all users can create at least 2 collection types (user and other)
  let!(:user_collection_type) { FactoryBot.create(:user_collection_type) }
  let!(:other_collection_type) do
    # make sure all users can create at least 2 collection types
    FactoryBot.create(:collection_type, title: "Other",
                                        creator_user: [manager.user_key, creator.user_key, user.user_key])
  end
  let!(:managed_collection_type) do
    FactoryBot.create(:collection_type, title: "Managed Collection",
                                        manager_user: manager.user_key, creator_user: creator.user_key)
  end

  context "when the user is not an admin" do
    context "and user does not have permissions to create managed collection type" do
      before do
        sign_in user
        click_link('Collections', match: :first)
      end

      it 'user is not offered the option to create that type of collection' do
        # try and create the new admin set
        click_button "New Collection"
        expect(page).to have_xpath("//h4", text: "User Collection")
        expect(page).to have_xpath("//h4", text: "Other")
        expect(page).not_to have_xpath("//h4", text: "Managed Collection")
      end
    end

    context "and user is a creator for managed collection type" do
      before do
        sign_in creator
        click_link('Collections', match: :first)
      end

      it 'creates the collection' do
        # create the new collection
        click_button "New Collection"
        expect(page).to have_xpath("//h4", text: "User Collection")
        expect(page).to have_xpath("//h4", text: "Other")
        expect(page).to have_xpath("//h4", text: "Managed Collection")
        choose "collection_type", option: "ManagedCollection"
        click_button 'Create collection'
        fill_in('Title', with: 'A Managed Collection')
        fill_in('Description', with: "This collection was created by #{creator.user_key}")
        click_on('Save')
        expect(page).to have_content("Collection was successfully created.")

        # navigate to show page for the new collection
        visit '/dashboard'
        click_link('Collections', match: :first)
        click_on('Display all details of A Managed Collection')

        # confirm creating user can view and edit the new collection
        expect(page).to have_xpath('//h2', text: 'A Managed Collection')
        expect(page).to have_content("This collection was created by #{creator.user_key}")
        expect(page).to have_link("Edit collection")

        # confirm admin can view and edit the new collection
        logout
        sign_in admin
        click_link('Collections', match: :first)
        click_link 'All Collections'
        click_on('Display all details of A Managed Collection')
        expect(page).to have_xpath('//h2', text: 'A Managed Collection')
        expect(page).to have_content("This collection was created by #{creator.user_key}")
        expect(page).to have_link("Edit collection")

        # confirm a collection type manager can view and edit the new collection
        logout
        sign_in manager
        click_link('Collections', match: :first)
        click_link 'Managed Collections'
        click_on('Display all details of A Managed Collection')
        expect(page).to have_xpath('//h2', text: 'A Managed Collection')
        expect(page).to have_content("This collection was created by #{creator.user_key}")
        expect(page).to have_link("Edit collection")
      end
    end

    context "and user is a manager for managed collection type" do
      before do
        sign_in manager
        click_link('Collections', match: :first)
      end

      it 'creates the collection' do
        # create the new collection
        click_button "New Collection"
        expect(page).to have_xpath("//h4", text: "User Collection")
        expect(page).to have_xpath("//h4", text: "Other")
        expect(page).to have_xpath("//h4", text: "Managed Collection")
        choose "collection_type", option: "ManagedCollection"
        click_button 'Create collection'
        fill_in('Title', with: 'A Managed Collection')
        fill_in('Description', with: "This collection was created by #{manager.user_key}")
        click_on('Save')
        expect(page).to have_content("Collection was successfully created.")

        # navigate to show page for the new collection
        visit '/dashboard'
        click_link('Collections', match: :first)
        click_on('Display all details of A Managed Collection')

        # confirm creating user can view and edit the new collection
        expect(page).to have_xpath('//h2', text: 'A Managed Collection')
        expect(page).to have_content("This collection was created by #{manager.user_key}")
        expect(page).to have_link("Edit collection")

        # confirm admin can view and edit the new collection
        logout
        sign_in admin
        click_link('Collections', match: :first)
        click_link 'All Collections'
        click_on('Display all details of A Managed Collection')
        expect(page).to have_xpath('//h2', text: 'A Managed Collection')
        expect(page).to have_content("This collection was created by #{manager.user_key}")
        expect(page).to have_link("Edit collection")

        # confirm a collection type creator can not view the new collection
        logout
        sign_in creator
        click_link('Collections', match: :first)
        expect(page).not_to have_content('Managed Collections')
        expect(page).not_to have_content('A Managed Collection')
      end
    end
  end

  context "when user is an admin" do
    before do
      sign_in admin
      click_link('Collections', match: :first)
    end

    it 'creates the collection' do
      # create the new collection
      click_button "New Collection"
      expect(page).to have_xpath("//h4", text: "User Collection")
      expect(page).to have_xpath("//h4", text: "Other")
      expect(page).to have_xpath("//h4", text: "Managed Collection")
      choose "collection_type", option: "ManagedCollection"
      click_button 'Create collection'
      fill_in('Title', with: 'A Managed Collection')
      fill_in('Description', with: "This collection was created by #{admin.user_key}")
      click_on('Save')
      expect(page).to have_content("Collection was successfully created.")

      # navigate to show page for the new collection
      visit '/dashboard'
      click_link('Collections', match: :first)
      click_on('Display all details of A Managed Collection')

      # confirm creating user can view and edit the new collection
      expect(page).to have_xpath('//h2', text: 'A Managed Collection')
      expect(page).to have_content("This collection was created by #{admin.user_key}")
      expect(page).to have_link("Edit collection")

      # confirm a collection type manager can view and edit the new collection
      logout
      sign_in manager
      click_link('Collections', match: :first)
      click_link 'Managed Collections'
      click_on('Display all details of A Managed Collection')
      expect(page).to have_xpath('//h2', text: 'A Managed Collection')
      expect(page).to have_content("This collection was created by #{admin.user_key}")
      expect(page).to have_link("Edit collection")

      # confirm a collection type creator can not view the new collection
      logout
      sign_in creator
      click_link('Collections', match: :first)
      expect(page).not_to have_content('Managed Collections')
      expect(page).not_to have_content('A Managed Collection')
    end
  end
end
