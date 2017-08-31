RSpec.describe 'collection', type: :feature do
  let(:user) { create(:user) }

  let(:collection1) { create(:public_collection, user: user) }
  let(:collection2) { create(:public_collection, user: user) }

  describe 'create collection' do
    before do
      sign_in user
      visit '/dashboard/my/collections'
    end

    let(:title) { "Test Collection" }
    let(:description) { "Description for collection we are testing." }

    it "makes a new collection" do
      click_link "New Collection"
      page.assert_text 'Create New Collection'
      click_link('Additional fields')

      expect(page).to have_selector "input.collection_creator.multi_value"
      expect(page).to have_selector "input.collection_title.multi_value"

      fill_in('Title', with: title)
      fill_in('Abstract or Summary', with: description)
      fill_in('Related URL', with: 'http://example.com/')

      click_button("Create Collection")
      page.assert_text 'Works in this Collection'
      page.assert_text title
      page.assert_text description
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
      page.assert_text "Works in this Collection"
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
      page.assert_text(collection.title.first)
      within('#document_' + collection.id) do
        first('button.dropdown-toggle').click
        first(".itemtrash").click
      end
      page.assert_no_text(collection.title.first)
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

    it "has creation date for collections" do
      page.assert_text(collection1.create_date.to_date.to_formatted_s(:standard))
    end

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      page.assert_text(collection.title.first)
      within('#document_' + collection.id) do
        click_link("Display all details of #{collection.title.first}")
      end
      page.assert_text(collection.title.first)
      page.assert_text(collection.description.first)
      # Should not show title and description a second time
      expect(page).not_to have_css('.metadata-collections', text: collection.title.first)
      expect(page).not_to have_css('.metadata-collections', text: collection.description.first)
      # Should not have Collection Descriptive metadata table
      page.assert_text("Descriptions")
      # Should have search results / contents listing
      page.assert_text(work1.title.first)
      page.assert_text(work2.title.first)
      expect(page).not_to have_css(".pager")

      click_link "Gallery"
      page.assert_text(work1.title.first)
      page.assert_text(work2.title.first)
    end

    it "hides collection descriptive metadata when searching a collection" do
      # URL: /dashboard/my/collections
      page.assert_text(collection.title.first)
      within("#document_#{collection.id}") do
        click_link("Display all details of #{collection.title.first}")
      end
      # URL: /dashboard/collections/collection-id
      page.assert_text(collection.title.first)
      page.assert_text(collection.description.first)
      page.assert_text(work1.title.first)
      page.assert_text(work2.title.first)
      fill_in('collection_search', with: work1.title.first)
      click_button('collection_submit')
      # Should not have Collection metadata table (only title and description)
      page.assert_no_text("Total works")
      page.assert_text(collection.title.first)
      page.assert_text(collection.description.first)
      # Should have search results / contents listing
      page.assert_text("Search Results")
      page.assert_text(work1.title.first)
      page.assert_no_text(work2.title.first)
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
      page.assert_text(collection.title.first)
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

    before do
      sign_in user
      visit '/dashboard/my/collections'
    end

    it "edits and update collection metadata" do
      # URL: /dashboard/collections
      page.assert_text(collection.title.first)
      within("#document_#{collection.id}") do
        find('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      # URL: /collections/collection-id/edit
      expect(page).to have_field('collection_title', with: collection.title.first)
      expect(page).to have_field('collection_description', with: collection.description.first)
      page.assert_text(work1.title.first)
      page.assert_text(work2.title.first)

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
      header.assert_no_text(collection.title.first)
      header.assert_no_text(collection.description.first)
      header.assert_text(new_title)
      page.assert_text(new_description)
      page.assert_text(creators.first)
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
      page.assert_text(collection.title.first)
      page.assert_text(collection.description.first)
      page.assert_no_text(work1.title.first)
      page.assert_text(work2.title.first)
    end

    xit "removes all works", :js do
      # TODO: skipping - see Hyrax issue #1488
      first('input#check_all').click
      click_button('Remove From Collection')
      page.assert_text(collection.title.first)
      page.assert_text(collection.description.first)
      page.assert_no_text(work1.title.first)
      page.assert_no_text(work2.title.first)
    end
  end
end
