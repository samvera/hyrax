RSpec.describe 'collection', type: :feature, clean_repo: true do
  include Selectors::Dashboard

  let(:user) { create(:user) }
  let(:admin_user) { create(:admin) }
  let(:collection_type) { create(:collection_type, creator_user: user) }
  let(:user_collection_type) { create(:user_collection_type) }
  let(:solr_gid_field) { Collection.collection_type_gid_document_field_name }
  let(:solr_model_field) { 'has_model_ssim' }

  # Setting Title on admin sets to avoid false positive matches with collections.
  let(:admin_set_a) { create(:admin_set, creator: [admin_user.user_key], title: ['Set A'], with_permission_template: true) }
  let(:admin_set_b) { create(:admin_set, creator: [user.user_key], title: ['Set B'], edit_users: [user.user_key], with_permission_template: true) }
  let(:collection1) { create(:public_collection_lw, user: user, collection_type_gid: collection_type.gid, with_permission_template: true) }
  let(:collection2) { create(:public_collection_lw, user: user, collection_type_gid: collection_type.gid, with_permission_template: true) }
  let(:collection3) { create(:public_collection_lw, user: admin_user, collection_type_gid: collection_type.gid, with_permission_template: true) }
  let(:collection4) { create(:public_collection_lw, user: admin_user, collection_type_gid: user_collection_type.gid, with_permission_template: true) }

  describe 'Your Collections tab' do
    context 'when non-admin user' do
      before do
        user
        admin_user
        admin_set_a
        admin_set_b
        create(:permission_template_access,
               :manage,
               permission_template: admin_set_b.permission_template,
               agent_type: 'user',
               agent_id: user.user_key)
        collection1
        collection2
        collection3
        collection4
        sign_in user
        visit '/dashboard/my/collections'
      end

      it "has page title, does not have tabs, lists only user's collections, and displays number of collections in the respository" do
        expect(page).to have_content 'Collections'
        expect(page).not_to have_link 'All Collections'
        within('section.tabs-row') do
          expect(page).not_to have_link 'Your Collections'
        end
        expect(page).to have_link(collection1.title.first)
        expect(page).to have_link(collection2.title.first)
        expect(page).to have_link(admin_set_b.title.first)
        expect(page).not_to have_link(collection3.title.first)
        expect(page).not_to have_link(admin_set_a.title.first)
        expect(page).to have_content("3 collections you own in the repository")
      end

      it "has collection type and visibility filters" do
        expect(page).to have_button 'Visibility'
        expect(page).to have_link 'Public',
                                  href: /visibility_ssi.+#{Regexp.escape(CGI.escape(collection3.visibility))}/
        expect(page).to have_button 'Collection Type'
        expect(page).to have_link collection_type.title,
                                  href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(collection_type.gid))}/
        expect(page).to have_link 'AdminSet',
                                  href: /#{solr_model_field}.+#{Regexp.escape('AdminSet')}/
        expect(page).not_to have_link user_collection_type.title,
                                      href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(user_collection_type.gid))}/
        expect(page).not_to have_link 'Collection',
                                      href: /#{solr_model_field}.+#{Regexp.escape('Collection')}/
      end
    end

    context 'when admin user' do
      before do
        user
        admin_user
        admin_set_a
        admin_set_b
        create(:permission_template_access,
               :manage,
               permission_template: admin_set_a.permission_template,
               agent_type: 'user',
               agent_id: admin_user.user_key)
        create(:permission_template_access,
               :manage,
               permission_template: admin_set_b.permission_template,
               agent_type: 'group',
               agent_id: 'admin')
        collection1
        collection2
        collection3
        collection4
        sign_in admin_user
        visit '/dashboard/my/collections'
      end

      it "has page title, has tabs for All Collections and Your Collections, and lists collections with edit access" do
        expect(page).to have_content 'Collections'
        expect(page).to have_link 'All Collections'
        expect(page).to have_link 'Your Collections'
        expect(page).to have_link(collection3.title.first)
        expect(page).to have_link(collection4.title.first)
        expect(page).to have_link(admin_set_a.title.first)
        expect(page).not_to have_link(collection1.title.first)
        expect(page).not_to have_link(collection2.title.first)
        expect(page).not_to have_link(admin_set_b.title.first)
      end

      it "has collection type and visibility filters" do
        expect(page).to have_button 'Visibility'
        expect(page).to have_link 'Public',
                                  href: /visibility_ssi.+#{Regexp.escape(CGI.escape(collection3.visibility))}/
        expect(page).to have_button 'Collection Type'
        expect(page).to have_link collection_type.title,
                                  href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(collection_type.gid))}/
        expect(page).to have_link user_collection_type.title,
                                  href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(user_collection_type.gid))}/
        expect(page).to have_link 'AdminSet',
                                  href: /#{solr_model_field}.+#{Regexp.escape('AdminSet')}/
        expect(page).not_to have_link 'Collection',
                                      href: /#{solr_model_field}.+#{Regexp.escape('Collection')}/
      end
    end
  end

  describe 'All Collections tab (for admin users only)' do
    before do
      user
      admin_user
      collection1
      collection2
      collection3
      collection4
      admin_set_a
      admin_set_b
      sign_in admin_user
      visit '/dashboard/my/collections'
    end

    it 'lists all collections for all users' do
      expect(page).to have_link 'All Collection'
      click_link 'All Collections'
      expect(page).to have_link(collection1.title.first)
      expect(page).to have_link(collection2.title.first)
      expect(page).to have_link(collection3.title.first)
      expect(page).to have_link(collection4.title.first)
      expect(page).to have_link(admin_set_a.title.first)
      expect(page).to have_link(admin_set_b.title.first)
    end

    it 'has a collection type filter' do
      expect(page).to have_link 'All Collection'
      click_link 'All Collections'
      expect(page).to have_button 'Visibility'
      expect(page).to have_link 'Public',
                                href: /visibility_ssi.+#{Regexp.escape(CGI.escape(collection1.visibility))}/
      expect(page).to have_button 'Collection Type'
      expect(page).to have_link collection_type.title,
                                href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(collection_type.gid))}/
      expect(page).to have_link user_collection_type.title,
                                href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(user_collection_type.gid))}/
      expect(page).to have_link 'AdminSet',
                                href: /#{solr_model_field}.+#{Regexp.escape('AdminSet')}/
      expect(page).not_to have_link 'Collection',
                                    href: /#{solr_model_field}.+#{Regexp.escape('Collection')}/
    end
  end

  describe 'Managed Collections tab (for non-admin users with shared access' do
    let(:user2) { create(:user) }

    before do
      user
      admin_user
      collection1
      collection2
      collection3
      collection4
      create(:permission_template_access,
             :manage,
             permission_template: collection1.permission_template,
             agent_type: 'user',
             agent_id: user2.user_key)
      collection1.reset_access_controls!
      create(:permission_template_access,
             :deposit,
             permission_template: collection2.permission_template,
             agent_type: 'user',
             agent_id: user2.user_key)
      collection2.reset_access_controls!
      create(:permission_template_access,
             :view,
             permission_template: collection4.permission_template,
             agent_type: 'user',
             agent_id: user2.user_key)
      collection4.reset_access_controls!
      sign_in user2
      visit '/dashboard/my/collections'
    end

    it 'lists managed collections only for user2' do
      expect(page).to have_link 'Managed Collections'
      click_link 'Managed Collections'
      expect(page).to have_link(collection1.title.first)
      expect(page).to have_link(collection2.title.first)
      expect(page).not_to have_link(collection3.title.first)
      expect(page).to have_link(collection4.title.first)
      expect(page).not_to have_link(admin_set_a.title.first)
      expect(page).not_to have_link(admin_set_b.title.first)
    end

    it 'has a collection type filter' do
      expect(page).to have_link 'Managed Collections'
      click_link 'Managed Collections'
      expect(page).to have_button 'Visibility'
      expect(page).to have_link 'Public',
                                href: /visibility_ssi.+#{Regexp.escape(CGI.escape(collection1.visibility))}/
      expect(page).to have_button 'Collection Type'
      expect(page).to have_link collection_type.title,
                                href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(collection_type.gid))}/
      expect(page).to have_link user_collection_type.title,
                                href: /#{solr_gid_field}.+#{Regexp.escape(CGI.escape(user_collection_type.gid))}/
      expect(page).not_to have_link 'AdminSet',
                                    href: /#{solr_model_field}.+#{Regexp.escape('AdminSet')}/
      expect(page).not_to have_link 'Collection',
                                    href: /#{solr_model_field}.+#{Regexp.escape('Collection')}/
    end
  end

  describe 'create collection' do
    let(:title) { "Test Collection" }
    let(:description) { "Description for collection we are testing." }

    context 'when user can create collections of multiple types' do
      before do
        collection_type
        user_collection_type

        sign_in user
        visit '/dashboard/my/collections'
      end

      it "makes a new collection", :js do
        click_button "New Collection"
        expect(page).to have_content 'Select type of collection'

        choose('User Collection')
        click_on('Create collection')

        expect(page).to have_selector('h1', text: 'New User Collection')
        expect(page).to have_selector "input.collection_title.multi_value"

        click_link('Additional fields')
        expect(page).to have_selector "input.collection_creator.multi_value"

        fill_in('Title', with: title)
        fill_in('Description', with: description)
        fill_in('Related URL', with: 'http://example.com/')

        click_button("Save")
        expect(page).to have_content title
        expect(page).to have_content description
      end

      it "has properly formed collection type buttons" do
        expect(page).not_to have_selector("input[data-path$='collections/new&collection_type_id=1']")
        expect(page).to have_selector("input[data-path$='collections/new?locale=en&collection_type_id=1']")
      end
    end

    context 'when user can create collections of one type' do
      before do
        user_collection_type

        sign_in user
        visit '/dashboard/my/collections'
      end

      it 'makes a new collection' do
        click_link "New Collection"
        expect(page).to have_selector('h1', text: 'New User Collection')
        expect(page).to have_selector "input.collection_title.multi_value"

        click_link('Additional fields')
        expect(page).to have_selector "input.collection_creator.multi_value"

        fill_in('Title', with: title)
        fill_in('Description', with: description)
        fill_in('Related URL', with: 'http://example.com/')

        click_button("Save")
        expect(page).to have_content title
        expect(page).to have_content description
      end
    end

    context 'when user can not create collections' do
      before do
        sign_in user
        visit '/dashboard/my/collections'
      end

      it 'does show New Collection button' do
        expect(page).not_to have_link "New Collection"
        expect(page).not_to have_button "New Collection"
      end
    end
  end

  # TODO: this section is still deactivated
  describe "adding works to a collection", skip: "we need to define a dashboard/works path" do
    let!(:collection) { create!(:collection, title: ["Barrel of monkeys"], user: user, with_permission_template: true) }
    let!(:work1) { create(:work, title: ["King Louie"], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], user: user) }

    before do
      sign_in user
    end

    it "attaches the works", :js do
      visit '/dashboard/my/works'
      first('input#check_all').click
      click_button "Add to collection" # opens the modal
      # since there is only one collection, it's not necessary to choose a radio button
      click_button "Update Collection"
      expect(page).to have_content "Works in this Collection"
      # There are two rows in the table per document (one for the general info, one for the details)
      # Make sure we have at least 2 documents
      expect(page).to have_selector "table.table-zebra-striped tr#document_#{work1.id}"
      expect(page).to have_selector "table.table-zebra-striped tr#document_#{work2.id}"
    end
  end

  describe 'delete collection' do
    let!(:empty_collection) { create(:public_collection_lw, title: ['Empty Collection'], user: user, with_permission_template: true) }
    let!(:collection) { create(:public_collection_lw, title: ['Collection with Work'], user: user, with_permission_template: true) }
    let!(:admin_user) { create(:admin) }
    let!(:empty_adminset) { create(:admin_set, title: ['Empty Admin Set'], creator: [admin_user.user_key], with_permission_template: true) }
    let!(:adminset) { create(:admin_set, title: ['Admin Set with Work'], creator: [admin_user.user_key], with_permission_template: true) }
    let!(:work) { create(:work, title: ["King Louie"], admin_set: adminset, member_of_collections: [collection], user: user) }

    # check table row has appropriate data attributes added
    def check_tr_data_attributes(id, type)
      url_fragment = get_url_fragment(type)
      expect(page).to have_selector("tr[data-id='#{id}'][data-colls-hash]")
      expect(page).to have_selector("tr[data-post-url='/dashboard/collections/#{id}/within?locale=en']")
      expect(page).to have_selector("tr[data-post-delete-url='/#{url_fragment}/#{id}?locale=en']")
    end

    # check data attributes have been transferred from table row to the modal
    def check_modal_data_attributes(id, type)
      url_fragment = get_url_fragment(type)
      expect(page).to have_selector("div[data-id='#{id}']")
      expect(page).to have_selector("div[data-post-delete-url='/#{url_fragment}/#{id}?locale=en']")
    end

    def get_url_fragment(type)
      (type == 'admin_set' ? 'admin/admin_sets' : 'dashboard/collections')
    end

    context 'when user created the collection' do
      before do
        user
        sign_in user
        visit '/dashboard/my/collections' # Your Collections tab
      end

      context 'and collection is empty' do
        it 'and user confirms delete, deletes the collection', :js do
          within("table#collections-list-table") do
            expect(page).to have_content(empty_collection.title.first)
          end
          check_tr_data_attributes(empty_collection.id, 'collection')
          # check that modal data attributes haven't been added yet
          expect(page).not_to have_selector("div[data-id='#{empty_collection.id}']")
          within('#document_' + empty_collection.id) do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end
          expect(page).to have_selector("div#collection-empty-to-delete-modal", visible: true)
          check_modal_data_attributes(empty_collection.id, 'collection')
          within("div#collection-empty-to-delete-modal") do
            click_button('Delete')
          end
          within("table#collections-list-table") do
            expect(page).not_to have_content(empty_collection.title.first)
          end
        end

        it 'and user cancels, does NOT delete the collection', :js do
          within("table#collections-list-table") do
            expect(page).to have_content(collection.title.first)
          end
          check_tr_data_attributes(empty_collection.id, 'collection')
          # check that modal data attributes haven't been added yet
          expect(page).not_to have_selector("div[data-id='#{empty_collection.id}']")
          within("#document_#{empty_collection.id}") do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end
          expect(page).to have_selector("div#collection-empty-to-delete-modal", visible: true)
          check_modal_data_attributes(empty_collection.id, 'collection')

          within("div#collection-empty-to-delete-modal") do
            click_button('Cancel')
          end
          within("table#collections-list-table") do
            expect(page).to have_content(collection.title.first)
          end
        end
      end

      context 'and collection is not empty' do
        it 'and user confirms delete, deletes the collection', :js do
          within("table#collections-list-table") do
            expect(page).to have_content(collection.title.first)
          end
          check_tr_data_attributes(collection.id, 'collection')
          within("#document_#{collection.id}") do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end
          expect(page).to have_selector("div#collection-to-delete-modal", visible: true)
          check_modal_data_attributes(collection.id, 'collection')
          within("div#collection-to-delete-modal") do
            find('button.modal-delete-button').click
          end
          within("table#collections-list-table") do
            expect(page).not_to have_content(collection.title.first)
          end
        end

        it 'and user cancels, does NOT delete the collection', :js do
          within("table#collections-list-table") do
            expect(page).to have_content(collection.title.first)
          end
          within("#document_#{collection.id}") do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end
          expect(page).to have_selector("div#collection-to-delete-modal", visible: true)

          within("div#collection-to-delete-modal") do
            click_button('Cancel')
          end
          within("table#collections-list-table") do
            expect(page).to have_content(collection.title.first)
          end
        end
      end
    end

    context 'when user does not have permission to delete a collection' do
      let(:user2) { create(:user) }

      before do
        create(:permission_template_access,
               :deposit,
               permission_template: collection.permission_template,
               agent_type: 'user',
               agent_id: user2.user_key)
        sign_in user2
        visit '/dashboard/collections' # Managed Collections tab
      end

      context 'and selects Delete from drop down within table' do
        it 'does not allow delete collection', js: true do
          expect(page).to have_content(collection.title.first)
          check_tr_data_attributes(collection.id, 'collection')
          within("#document_#{collection.id}") do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end

          # Exepct the modal to be shown that explains why the user can't delete the collection.
          expect(page).to have_selector('div#collection-to-delete-deny-modal', visible: true)
          within('div#collection-to-delete-deny-modal') do
            click_button('Close')
          end
          expect(page).to have_content(collection.title.first)
        end
      end
    end

    context 'when user created the admin set' do
      before do
        sign_in admin_user
        visit '/dashboard/collections' # All Collections tab
      end

      context 'and admin set is empty' do
        it 'and user confirms delete, deletes the admin set', :js do
          expect(page).to have_content(empty_adminset.title.first)
          check_tr_data_attributes(empty_adminset.id, 'admin_set')
          within('#document_' + empty_adminset.id) do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end
          expect(page).to have_selector("div#collection-empty-to-delete-modal", visible: true)
          check_modal_data_attributes(empty_adminset.id, 'admin_set')
          within("div#collection-empty-to-delete-modal") do
            find('button.modal-delete-button').click
          end
          expect(page).not_to have_content(empty_adminset.title.first)
        end

        it 'and user cancels, does NOT delete the admin set', :js do
          expect(page).to have_content(empty_adminset.title.first)
          check_tr_data_attributes(empty_adminset.id, 'admin_set')
          within("#document_#{empty_adminset.id}") do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end
          expect(page).to have_selector("div#collection-empty-to-delete-modal", visible: true)
          check_modal_data_attributes(empty_adminset.id, 'admin_set')
          within("div#collection-empty-to-delete-modal") do
            click_button('Cancel')
          end
          expect(page).to have_content(empty_adminset.title.first)
        end
      end

      context 'and admin set is not empty' do
        it 'does not allow delete admin set' do
          expect(page).to have_content(adminset.title.first)
          check_tr_data_attributes(adminset.id, 'admin_set')
          within("#document_#{adminset.id}") do
            first('button.dropdown-toggle').click
            first('.itemtrash').click
          end
          expect(page).to have_selector("div#collection-admin-set-delete-deny-modal", visible: true)
          within("div#collection-admin-set-delete-deny-modal") do
            click_button('Close')
          end
          expect(page).to have_content(adminset.title.first)
        end
      end
    end

    context 'when user without permissions selects delete' do
      let(:user2) { create(:user) }

      before do
        create(:permission_template_access,
               :view,
               permission_template: adminset.permission_template,
               agent_type: 'user',
               agent_id: user2.user_key)
        sign_in user2
        visit '/dashboard/collections' # Managed Collections tab
      end

      xit 'does not allow delete admin set' do
        # TODO: Depositors & viewers cannot see admin sets in Managed Collections list.  Should they?
        expect(page).to have_content(adminset.title.first)
        within("#document_#{adminset.id}") do
          first('button.dropdown-toggle').click
          first('.itemtrash').click
        end
        expect(page).to have_selector('div#collection-to-delete-deny-modal', visible: true)
        within('div#collection-to-delete-deny-modal') do
          click_button('Close')
        end
        expect(page).to have_content(adminset.title.first)
      end
    end
  end

  describe 'collection show page' do
    let(:collection) do
      build(:public_collection_lw, user: user, description: ['collection description'], with_permission_template: true)
    end
    let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection], user: user) }

    before do
      sign_in user
      visit '/dashboard/my/collections'
    end

    it "has creation date for collections and shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      expect(page).to have_content(collection.create_date.to_date.to_formatted_s(:standard))

      expect(page).to have_content(collection.title.first)
      within('#document_' + collection.id) do
        click_link("Display all details of #{collection.title.first}")
      end
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      # Should not show title and description a second time
      expect(page).not_to have_css('.metadata-collections', text: collection.title.first)
      expect(page).not_to have_css('.metadata-collections', text: collection.description.first)
      # Should not have Collection Descriptive metadata table
      expect(page).to have_content("Descriptions")
      # Should have search results / contents listing
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      expect(page).not_to have_css(".pagination")

      click_link "Gallery"
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end

    it "hides collection descriptive metadata when searching a collection" do
      # URL: /dashboard/my/collections
      expect(page).to have_content(collection.title.first)
      within("#document_#{collection.id}") do
        click_link("Display all details of #{collection.title.first}")
      end
      # URL: /dashboard/collections/collection-id
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      fill_in('collection_search', with: work1.title.first)
      click_button('collection_submit')
      # Should not have Collection metadata table (only title and description)
      expect(page).not_to have_content("Total works")
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      # Should have search results / contents listing
      expect(page).to have_content("Search Results")
      expect(page).to have_content(work1.title.first)
      expect(page).not_to have_content(work2.title.first)
    end

    context 'adding existing works to a collection', js: true do
      before do
        collection1 # create collections by referencing them
        collection2
        sign_in user
      end

      it "preselects the collection we are adding works to and adds the selected works" do
        visit "/dashboard/collections/#{collection1.id}"
        click_link 'Add existing works'
        find('input#check_all').click
        click_button "Add to collection"
        expect(page).to have_selector "#member_of_collection_ids[value=\"#{collection1.id}\"]", visible: false
        expect(page).to have_selector "#member_of_collection_label[value=\"#{collection1.title.first}\"]"

        visit "/dashboard/collections/#{collection2.id}"
        click_link 'Add existing works'
        find('input#check_all').click
        click_button "Add to collection"
        expect(page).to have_selector "#member_of_collection_ids[value=\"#{collection2.id}\"]", visible: false
        expect(page).to have_selector "#member_of_collection_label[value=\"#{collection2.title.first}\"]"

        click_button "Save changes"
        expect(page).to have_content(work1.title.first)
        expect(page).to have_content(work2.title.first)
      end
    end

    context 'adding a new works to a collection', js: true do
      before do
        collection1 # create collections by referencing them
        collection2
        sign_in user
        # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
        allow(CharacterizeJob).to receive(:perform_later)
      end

      it "preselects the collection we are adding works to and adds the new work" do
        visit "/dashboard/collections/#{collection1.id}"
        click_link 'Deposit new work through this collection'
        choose "payload_concern", option: "GenericWork"
        click_button 'Create work'

        # verify the collection is pre-selected
        click_link "Relationships" # switch tab
        expect(page).to have_selector("table tr", text: collection1.title.first)
        expect(page).not_to have_selector("table tr", text: collection2.title.first)

        # add required file
        click_link "Files" # switch tab
        within('span#addfiles') do
          attach_file("files[]", "fixtures/image.jp2", visible: false)
        end
        # set required metadata
        click_link "Descriptions" # switch tab
        fill_in('Title', with: 'New Work for Collection')
        fill_in('Creator', with: 'Doe, Jane')
        fill_in('Keyword', with: 'testing')
        select('In Copyright', from: 'Rights statement')
        # check required acceptance
        check('agreement')

        click_on('Save')

        # verify new work was added to collection1
        visit "/dashboard/collections/#{collection1.id}"
        expect(page).to have_content("New Work for Collection")
      end
    end
  end

  # TODO: this is just like the block above. Merge them.
  describe 'show pages of a collection' do
    before do
      docs = (0..12).map do |n|
        { "has_model_ssim" => ["GenericWork"], :id => "zs25x871q#{n}",
          "depositor_ssim" => [user.user_key],
          "suppressed_bsi" => false,
          "member_of_collection_ids_ssim" => [collection.id],
          "nesting_collection__parent_ids_ssim" => [collection.id],
          "edit_access_person_ssim" => [user.user_key] }
      end
      ActiveFedora::SolrService.add(docs, commit: true)

      sign_in user
    end
    let(:collection) { create(:named_collection_lw, user: user, with_permission_template: true) }

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit '/dashboard/my/collections'
      expect(page).to have_content(collection.title.first)
      within('#document_' + collection.id) do
        # Now go to the collection show page
        click_link("Display all details of collection title")
      end
      expect(page).to have_css(".pagination")
    end
  end

  describe 'remove works from collection' do
    context 'user that can edit' do
      let!(:work2) { create(:work, title: ["King Louie"], member_of_collections: [collection1], user: user) }
      let!(:work1) { create(:work, title: ["King Kong"], member_of_collections: [collection1], user: user) }

      before do
        sign_in admin_user
      end
      # TODO: move this test to a view unit test (and solve the missing warden problem when using Ability in view tests)
      it 'shows remove action buttons' do
        visit "/dashboard/collections/#{collection1.id}"
        expect(page).to have_selector('input.collection-remove', count: 2)
      end
      it 'removes the first work from the list of items' do
        visit "/dashboard/collections/#{collection1.id}"
        expect(page).to have_selector('input.collection-remove', count: 2)
        page.all('input.collection-remove')[0].click
        expect(page).to have_selector('input.collection-remove', count: 1)
        # because works do not have order, you cannot guarentee that the first work added is the work getting deleted
        has_work1 = page.has_content? work1.title.first
        has_work2 = page.has_content? work2.title.first
        expect(has_work1 ^ has_work2).to be true
      end
      xit 'removes a sub-collection from the list of items (dependency on collection nesting)' do
      end
    end
    context 'user that cannot edit' do
      let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection3], user: user) }
      let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection3], user: user) }

      before do
        sign_in user
      end
      # TODO: move this test to a view unit test (and solve the missing warden problem when using Ability in view tests)
      it 'does not show remove action buttons' do
        visit "/dashboard/collections/#{collection3.id}"
        expect(page).not_to have_selector 'input.collection-remove'
      end
    end
  end

  describe 'edit collection' do
    let(:collection) { build(:named_collection_lw, user: user, with_permission_template: true) }
    let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection], user: user) }

    context 'from dashboard -> collections action menu' do
      before do
        create(:permission_template_access,
               :deposit,
               permission_template: collection1.permission_template,
               agent_type: 'user',
               agent_id: user.user_key)

        collection1
        sign_in user
        visit '/dashboard/my/collections'
      end

      it "edit denied because user does not have permissions" do
        # URL: /dashboard/my/collections
        expect(page).to have_content(collection1.title.first)
        within("#document_#{collection1.id}") do
          find('button.dropdown-toggle').click
          click_link('Edit collection')
        end
        expect(page).to have_content(collection1.title.first)
      end
    end

    context 'from dashboard -> collections action menu' do
      context 'for a collection' do
        before do
          sign_in user
          visit '/dashboard/my/collections'
        end

        it "edits and update collection metadata" do
          # URL: /dashboard/my/collections
          expect(page).to have_content(collection.title.first)
          within("#document_#{collection.id}") do
            find('button.dropdown-toggle').click
            click_link('Edit collection')
          end
          # URL: /dashboard/collections/collection-id/edit
          expect(page).to have_selector('h1', text: "Edit User Collection: #{collection.title.first}")

          expect(page).to have_field('collection_title', with: collection.title.first)
          expect(page).to have_field('collection_description', with: collection.description.first)

          new_title = "Altered Title"
          new_description = "Completely new Description text."
          creators = ["Dorje Trollo", "Vajrayogini"]

          fill_in('Title', with: new_title)
          fill_in('Description', with: new_description)
          fill_in('Creator', with: creators.first)
          within('.panel-footer') do
            click_button('Save changes')
          end
          # URL: /dashboard/collections/collection-id/edit
          expect(page).not_to have_field('collection_title', with: collection.title.first)
          expect(page).not_to have_field('collection_description', with: collection.description.first)
          expect(page).to have_field('collection_title', with: new_title)
          expect(page).to have_field('collection_description', with: new_description)
          expect(page).to have_field('collection_creator', with: creators.first)
        end
      end

      context 'for an admin set' do
        before do
          admin_user
          admin_set_a
          sign_in admin_user
          visit '/dashboard/my/collections'
        end

        it 'edits admin set', :js do
          # URL: /dashboard/my/collections
          expect(page).to have_content(admin_set_a.title.first)
          within("#document_#{admin_set_a.id}") do
            find('button.dropdown-toggle').click
            click_link('Edit collection')
          end
          # URL: /dashboard/collections/collection-id/edit
          expect(page).to have_selector('h1', text: "Edit Administrative Set: #{admin_set_a.title.first}")
        end
      end
    end

    context "edit view tabs" do
      before do
        sign_in user
      end

      context 'with brandable set' do
        let(:brandable_collection_id) { create(:collection_lw, user: user, collection_type_settings: [:brandable], with_permission_template: true).id }
        let(:not_brandable_collection_id) { create(:collection_lw, user: user, collection_type_settings: [:not_brandable], with_permission_template: true).id }

        it 'to true, it shows Branding tab' do
          visit "/dashboard/collections/#{brandable_collection_id}/edit"
          expect(page).to have_link('Branding', href: '#branding')
        end

        it 'to false, it hides Branding tab' do
          visit "/dashboard/collections/#{not_brandable_collection_id}/edit"
          expect(page).not_to have_link('Branding', href: '#branding')
        end
      end

      context 'with discoverable set' do
        let(:discoverable_collection_id) { create(:collection_lw, user: user, collection_type_settings: [:discoverable], with_permission_template: true).id }
        let(:not_discoverable_collection_id) { create(:collection_lw, user: user, collection_type_settings: [:not_discoverable], with_permission_template: true).id }

        it 'to true, it shows Discovery tab' do
          visit "/dashboard/collections/#{discoverable_collection_id}/edit"
          expect(page).to have_link('Discovery', href: '#discovery')
        end

        it 'to false, it hides Discovery tab' do
          visit "/dashboard/collections/#{not_discoverable_collection_id}/edit"
          expect(page).not_to have_link('Discovery', href: '#discovery')
        end
      end

      context 'with sharable set' do
        let(:sharable_collection_id) { create(:collection_lw, user: user, collection_type_settings: [:sharable], with_permission_template: true).id }
        let(:not_sharable_collection_id) { create(:collection_lw, user: user, collection_type_settings: [:not_sharable], with_permission_template: true).id }

        it 'to true, it shows Sharable tab' do
          visit "/dashboard/collections/#{sharable_collection_id}/edit"
          expect(page).to have_link('Sharing', href: '#sharing')
        end

        context "to true, limits available users", js: true do
          let(:user2) { create(:user) }
          it "to system users filted by select2" do
            visit "/dashboard/collections/#{sharable_collection_id}/edit"
            expect(page).to have_link('Sharing', href: '#sharing')
            click_link('Sharing')
            expect(page).to have_selector(".form-inline.add-users .select2-container")
            select_user(user2, 'Depositor')
            click_button('Save')
            click_link('Sharing')
            expect(page).to have_selector('td', text: user2.user_key)
          end
        end

        it 'to false, it hides Sharable tab' do
          visit "/dashboard/collections/#{not_sharable_collection_id}/edit"
          expect(page).not_to have_link('Sharing', href: '#sharing')
        end
      end
    end
  end
end
