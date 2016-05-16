require 'spec_helper'

describe 'collection', type: :feature do
  let(:user) { create(:user) }

  let(:work1) { create(:work, title: ["King Louie"], user: user) }
  let(:work2) { create(:work, title: ["King Kong"], user: user) }
  let(:collection1) { create(:public_collection, user: user) }
  let(:collection2) { create(:public_collection, user: user) }

  describe 'create collection' do
    before do
      sign_in user
    end

    let(:title) { "Test Collection" }
    let(:description) { "Description for collection we are testing." }

    it "makes a new collection", :js do
      visit '/dashboard'
      first('#hydra-collection-add').click
      expect(page).to have_content 'Create New Collection'

      # Creator is a multi-value field, so it should have button to add more fields
      expect(page).to have_selector "div.collection_creator .input-append button.add"

      # Title is a multi-value field, so it should have the add another button
      expect(page).to have_selector "div.collection_title .input-append button.add"

      fill_in('Title', with: title)
      fill_in('Abstract or Summary', with: description)
      fill_in('Location', with: 'Over there')
      fill_in('Related URL', with: 'http://example.com/')
      click_button("Create Collection")
      expect(page).to have_content 'Items in this Collection'
      expect(page).to have_content title
      expect(page).to have_content description
    end
  end

  describe "adding works to a collection", skip: "we need to define a dashboard/works path" do
    let!(:collection) { create!(:collection, title: ["Barrel of monkeys"], user: user) }

    before do
      work1
      work2
      sign_in user
    end

    it "attaches the works", :js do
      visit '/dashboard/works'
      first('input#check_all').click
      click_button "Add to Collection" # opens the modal
      # since there is only one collection, it's not necessary to choose a radio button
      click_button "Update Collection"
      expect(page).to have_content "Items in this Collection"
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
      visit '/dashboard/collections'
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
    let!(:collection) do
      create(:public_collection, description: ["Collection description"], members: [work1, work2], user: user)
    end
    before do
      sign_in user
      visit '/dashboard/collections'
    end

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
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
      expect(page).to_not have_css(".pager")

      click_link "Gallery"
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end

    it "hides collection descriptive metadata when searching a collection" do
      # URL: /dashboard/collections
      expect(page).to have_content(collection.title.first)
      within("#document_#{collection.id}") do
        click_link("Display all details of #{collection.title.first}")
      end
      # URL: /collections/collection-id
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      fill_in('collection_search', with: work1.title.first)
      click_button('collection_submit')
      # Should not have Collection metadata table (only title and description)
      expect(page).not_to have_content("Total Items")
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      # Should have search results / contents listing
      expect(page).to have_content("Search Results")
      expect(page).to have_content(work1.title.first)
      expect(page).to_not have_content(work2.title.first)
    end
  end

  describe 'collection sorting' do
    before do
      collection1 # create the collections by referencing them
      sleep(1) # make sure the timestamps aren't equal
      collection2
      sleep(1)
      collection1.title = ['changed']
      collection1.save
      # collection 1 is now earlier when sorting by create date but later
      # when sorting by modified date

      sign_in user
      visit '/dashboard/collections'
    end

    it "has creation date for collections" do
      expect(page).to have_content(collection1.create_date.to_date.to_formatted_s(:standard))
    end

    it "allows changing sort order" do
      find(:xpath, "//select[@id='sort']/option[contains(., 'date modified')][contains(@value, 'asc')]") \
        .select_option
      click_button('Refresh')
      expect(page).to have_css("#document_#{collection1.id}")
      expect(page).to have_css("#document_#{collection2.id}")
      expect(page.body.index("id=\"document_#{collection1.id}")).to be > page.body.index("id=\"document_#{collection2.id}")

      find(:xpath, "//select[@id='sort']/option[contains(., 'date modified')][contains(@value, 'desc')]") \
        .select_option
      click_button('Refresh')
      expect(page).to have_css("#document_#{collection1.id}")
      expect(page).to have_css("#document_#{collection2.id}")
      expect(page.body.index("id=\"document_#{collection1.id}")).to be < page.body.index("id=\"document_#{collection2.id}")
    end
  end

  describe 'add works to collection' do
    before do
      collection1 # create collections by referencing them
      collection2
      sign_in user
    end

    it "preselects the collection we are adding works to" do
      visit "/collections/#{collection1.id}"
      click_link 'Add files'
      first('input#check_all').click
      click_button "Add to Collection"
      expect(page).to have_css("input#id_#{collection1.id}[checked='checked']")
      expect(page).not_to have_css("input#id_#{collection2.id}[checked='checked']")

      visit "/collections/#{collection2.id}"
      click_link 'Add files'
      first('input#check_all').click
      click_button "Add to Collection"
      expect(page).not_to have_css("input#id_#{collection1.id}[checked='checked']")
      expect(page).to have_css("input#id_#{collection2.id}[checked='checked']")
    end
  end

  describe 'edit collection' do
    let!(:collection) { create(:named_collection, members: [work1, work2], user: user) }

    before do
      sign_in user
      visit '/dashboard/collections'
    end

    it "edits and update collection metadata" do
      # URL: /dashboard/collections
      expect(page).to have_content(collection.title.first)
      within("#document_#{collection.id}") do
        find('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      # URL: /collections/collection-id/edit
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
      within('.primary-actions') do
        click_button('Update Collection')
      end
      # URL: /collections/collection-id
      header = find('header')
      expect(header).not_to have_content(collection.title.first)
      expect(header).not_to have_content(collection.description.first)
      expect(header).to have_content(new_title)
      expect(page).to have_content(new_description)
      expect(page).to have_content(creators.first)
    end
  end

  describe "Removing a files from a collection" do
    let!(:collection) { create(:named_collection, members: [work1, work2], user: user) }

    before do
      sign_in user
      visit "/collections/#{collection.id}/edit"
    end

    it "removes one file out of two" do
      within("#document_#{work1.id}") do
        first('button.dropdown-toggle').click
        click_button('Remove from Collection')
      end
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).not_to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end

    it "removes all files", :js do
      first('input#check_all').click
      click_button('Remove From Collection')
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).not_to have_content(work1.title.first)
      expect(page).not_to have_content(work2.title.first)
    end
  end

  describe 'show pages of a collection' do
    let(:works)       { (0..12).map { create(:work, user: user) } }
    let!(:collection) { create(:named_collection, members: works, user: user) }

    before { sign_in user }

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit '/dashboard/collections'
      expect(page).to have_content(collection.title.first)
      within('#document_' + collection.id) do
        click_link("Display all details of collection title")
      end
      expect(page).to have_css(".pager")
    end
  end
end
