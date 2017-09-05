RSpec.describe 'collection', type: :feature, clean_repo: true do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin) }
  let(:collection_type) { create(:collection_type, creator_user: user) }
  let(:user_collection_type) { create(:user_collection_type) }

  let(:collection1) { create(:public_collection, user: user, collection_type_gid: collection_type.gid) }
  let(:collection2) { create(:public_collection, user: user, collection_type_gid: collection_type.gid) }
  let(:collection3) { create(:public_collection, user: admin_user, collection_type_gid: collection_type.gid) }

  describe 'Your Collections tab' do
    context 'when non-admin user' do
      before do
        user
        admin_user
        collection1
        collection2
        collection3
        sign_in user
        visit '/dashboard/my/collections'
      end

      it "has page title, does not have tabs, and lists only user's collections" do
        expect(page).to have_content 'Collections'
        expect(page).not_to have_link 'All Collections'
        expect(page).not_to have_link 'Your Collections'
        expect(page).to have_link(collection1.title.first)
        expect(page).to have_link(collection2.title.first)
        expect(page).not_to have_link(collection3.title.first)
      end
    end

    context 'when admin user' do
      before do
        user
        admin_user
        collection1
        collection2
        collection3
        sign_in admin_user
        visit '/dashboard/my/collections'
      end

      it "has page title, has tabs for All and Your Collections, and lists only admin_user's collections" do
        expect(page).to have_content 'Collections'
        expect(page).to have_link 'All Collections'
        expect(page).to have_link 'Your Collections'
        expect(page).not_to have_link(collection1.title.first)
        expect(page).not_to have_link(collection2.title.first)
        expect(page).to have_link(collection3.title.first)
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
      sign_in admin_user
      visit '/dashboard/my/collections'
    end

    it 'lists all collections for all users' do
      expect(page).to have_link 'All Collection'
      click_link 'All Collections'
      expect(page).to have_link(collection1.title.first)
      expect(page).to have_link(collection2.title.first)
      expect(page).to have_link(collection3.title.first)
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

        expect(page).to have_content 'Create New Collection'
        expect(page).to have_selector "input.collection_title.multi_value"

        click_link('Additional fields')
        expect(page).to have_selector "input.collection_creator.multi_value"

        fill_in('Title', with: title)
        fill_in('Abstract or Summary', with: description)
        fill_in('Related URL', with: 'http://example.com/')

        click_button("Create Collection")
        expect(page).to have_content 'Items'
        expect(page).to have_content title
        expect(page).to have_content description
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
        expect(page).to have_content 'Create New Collection'
        expect(page).to have_selector "input.collection_title.multi_value"

        click_link('Additional fields')
        expect(page).to have_selector "input.collection_creator.multi_value"

        fill_in('Title', with: title)
        fill_in('Abstract or Summary', with: description)
        fill_in('Related URL', with: 'http://example.com/')

        click_button("Create Collection")
        expect(page).to have_content 'Items'
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

  describe "adding works to a collection", skip: "we need to define a dashboard/works path" do
    let!(:collection) { create!(:collection, title: ["Barrel of monkeys"], user: user) }
    let!(:work1) { create(:work, title: ["King Louie"], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], user: user) }

    before do
      sign_in user
    end

    it "attaches the works", :js do
      visit '/dashboard/my/works'
      first('input#check_all').click
      click_button "Add to Collection" # opens the modal
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
    let!(:collection) { create(:public_collection, user: user) }

    before do
      sign_in user
      visit '/dashboard/my/collections'
    end

    it "deletes a collection" do
      expect(page).to have_content(collection.title.first)
      within('#document_' + collection.id) do
        first('button.dropdown-toggle').click
        first(".itemtrash").click
      end
      expect(page).not_to have_content(collection.title.first)
    end
  end

  describe 'collection show page' do
    let(:collection) do
      create(:public_collection, user: user, description: ['collection description'])
    end
    let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection], user: user) }

    before do
      sign_in user
      visit '/dashboard/my/collections'
    end

    it "has creation date for collections and shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      expect(page).to have_content(collection1.create_date.to_date.to_formatted_s(:standard))

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
      expect(page).not_to have_css(".pager")

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
  end

  # TODO: this is just like the block above. Merge them.
  describe 'show pages of a collection' do
    before do
      docs = (0..12).map do |n|
        { "has_model_ssim" => ["GenericWork"], :id => "zs25x871q#{n}",
          "depositor_ssim" => [user.user_key],
          "suppressed_bsi" => false,
          "member_of_collection_ids_ssim" => [collection.id],
          "edit_access_person_ssim" => [user.user_key] }
      end
      ActiveFedora::SolrService.add(docs, commit: true)

      sign_in user
    end
    let(:collection) { create(:named_collection, user: user) }

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit '/dashboard/my/collections'
      expect(page).to have_content(collection.title.first)
      within('#document_' + collection.id) do
        # Now go to the collection show page
        click_link("Display all details of collection title")
      end
      expect(page).to have_css(".pager")
    end
  end

  describe 'add works to collection' do
    before do
      collection1 # create collections by referencing them
      collection2
      sign_in user
    end

    it "preselects the collection we are adding works to" do
      visit "/dashboard/collections/#{collection1.id}"
      click_link 'Add works'
      first('input#check_all').click
      click_button "Add to Collection"
      expect(page).to have_css("input#id_#{collection1.id}[checked='checked']")
      expect(page).not_to have_css("input#id_#{collection2.id}[checked='checked']")

      visit "/dashboard/collections/#{collection2.id}"
      click_link 'Add works'
      first('input#check_all').click
      click_button "Add to Collection"
      expect(page).not_to have_css("input#id_#{collection1.id}[checked='checked']")
      expect(page).to have_css("input#id_#{collection2.id}[checked='checked']")
    end
  end

  describe 'edit collection' do
    let(:collection) { create(:named_collection, user: user) }
    let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection], user: user) }

    context 'from dashboard -> collections action menu' do
      before do
        sign_in user
        visit '/dashboard/my/collections'
      end

      it "edits and update collection metadata" do
        # URL: /dashboard/collections
        expect(page).to have_content(collection.title.first)
        within("#document_#{collection.id}") do
          find('button.dropdown-toggle').click
          click_link('Edit Collection')
        end
        # URL: /dashboard/collections/collection-id/edit
        expect(page).to have_field('collection_title', with: collection.title.first)
        expect(page).to have_field('collection_description', with: collection.description.first)
        expect(page).to have_content(work1.title.first)
        expect(page).to have_content(work2.title.first)

        new_title = "Altered Title"
        new_description = "Completely new Description text."
        creators = ["Dorje Trollo", "Vajrayogini"]
        fill_in('Title', with: new_title)
        fill_in('Abstract or Summary', with: new_description)
        fill_in('Creator', with: creators.first)
        within('.panel-footer') do
          click_button('Update Collection')
        end
        # URL: /dashboard/collections/collection-id
        header = find('header')
        expect(header).not_to have_content(collection.title.first)
        expect(header).not_to have_content(collection.description.first)
        expect(header).to have_content(new_title)
        expect(page).to have_content(new_description)
        expect(page).to have_content(creators.first)
      end
    end

    context "tabs" do
      before do
        sign_in user
      end

      xit 'always includes branding' do # TODO: Pending PR for branding
        visit "/dashboard/collections/#{collection.id}/edit"
        expect(page).to have_content('Edit Collection')
        expect(page).to have_link('Branding', href: '#branding')
      end

      context 'with discoverable set' do
        let(:discoverable_collection_id) { create(:collection, user: user, collection_type_settings: [:discoverable]).id }
        let(:not_discoverable_collection_id) { create(:collection, user: user, collection_type_settings: [:not_discoverable]).id }

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
        let(:sharable_collection_id) { create(:collection, user: user, collection_type_settings: [:sharable]).id }
        let(:not_sharable_collection_id) { create(:collection, user: user, collection_type_settings: [:not_sharable]).id }

        it 'to true, it shows Sharable tab' do
          visit "/dashboard/collections/#{sharable_collection_id}/edit"
          expect(page).to have_link('Sharing', href: '#sharing')
        end

        it 'to false, it hides Sharable tab' do
          visit "/dashboard/collections/#{not_sharable_collection_id}/edit"
          expect(page).not_to have_link('Sharing', href: '#sharing')
        end
      end
    end
  end

  describe "Removing works from a collection" do
    let(:collection) { create(:named_collection, user: user) }
    let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection], user: user) }

    before do
      sign_in user
      visit "/dashboard/collections/#{collection.id}/edit"
    end

    it "removes one works out of two" do
      within("#document_#{work1.id}") do
        first('button.dropdown-toggle').click
        click_button('Remove from Collection')
      end
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).not_to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end

    xit "removes all works", :js do
      # TODO: skipping - see Hyrax issue #1488
      first('input#check_all').click
      click_button('Remove From Collection')
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).not_to have_content(work1.title.first)
      expect(page).not_to have_content(work2.title.first)
    end
  end
end
