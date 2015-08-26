require 'spec_helper'

describe 'collection', type: :feature do
  let(:user) { create(:user) }

  let(:work1) do
    GenericWork.create(title: ["King Louie"]) do |f|
      f.apply_depositor_metadata(user.user_key)
    end
  end

  let(:work2) do
    GenericWork.create(title: ["King Kong"]) do |f|
      f.apply_depositor_metadata(user.user_key)
    end
  end

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

      # Title is a single-value field, so it should not have the adder button
      expect(page).to_not have_selector "div.collection_title .input-append button.add"

      fill_in('Title', with: title)
      fill_in('Abstract or Summary', with: description)
      click_button("Create Collection")
      expect(page).to have_content 'Items in this Collection'
      expect(page).to have_content title
      expect(page).to have_content description
    end
  end

  describe "adding works to a collection", skip: "we need to define a dashboard/works path" do
    let!(:collection) do
      Collection.create!(title: "Barrel of monkeys") do |c|
        c.apply_depositor_metadata(user)
      end
    end

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
    let!(:collection) do
      Collection.create(title: "Barrel of monkeys", description: 'apes of the cinema') do |c|
        c.apply_depositor_metadata(user.user_key)
      end
    end
    before do
      sign_in user
      visit '/dashboard/collections'
    end

    it "deletes a collection" do
      expect(page).to have_content(collection.title)
      within('#document_' + collection.id) do
        first('button.dropdown-toggle').click
        first(".itemtrash").click
      end
      expect(page).not_to have_content(collection.title)
    end
  end

  describe 'collection show page' do
    let!(:collection) do
      Collection.create(title: 'collection title', description: 'collection description',
                        members: [work1, work2]) do |c|
        c.apply_depositor_metadata(user.user_key)
      end
    end
    before do
      sign_in user
      visit '/dashboard/collections'
    end

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      expect(page).to have_content(collection.title)
      within('#document_' + collection.id) do
        click_link("Display all details of collection title")
      end
      expect(page).to have_content(collection.title)
      expect(page).to have_content(collection.description)
      # Should not show title and description a second time
      expect(page).to_not have_css('.metadata-collections', text: collection.title)
      expect(page).to_not have_css('.metadata-collections', text: collection.description)
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
      expect(page).to have_content(collection.title)
      within("#document_#{collection.id}") do
        click_link("Display all details of collection title")
      end
      # URL: /collections/collection-id
      expect(page).to have_content(collection.title)
      expect(page).to have_content(collection.description)
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      fill_in('collection_search', with: work1.title.first)
      click_button('collection_submit')
      # Should not have Collection metadata table (only title and description)
      expect(page).to_not have_content("Total Items")
      expect(page).to have_content(collection.title)
      expect(page).to have_content(collection.description)
      # Should have search results / contents listing
      expect(page).to have_content("Search Results")
      expect(page).to have_content(work1.title.first)
      expect(page).to_not have_content(work2.title.first)
    end
  end

  describe 'edit collection' do
    let!(:collection) do
      Collection.create(title: 'collection title', description: 'collection description',
                        members: [work1, work2]) { |c| c.apply_depositor_metadata(user.user_key) }
    end

    before do
      sign_in user
      visit '/dashboard/collections'
    end

    it "edits and update collection metadata" do
      # URL: /dashboard/collections
      expect(page).to have_content(collection.title)
      within("#document_#{collection.id}") do
        find('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      # URL: /collections/collection-id/edit
      expect(page).to have_field('collection_title', with: collection.title)
      expect(page).to have_field('collection_description', with: collection.description)
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
      expect(header).to_not have_content(collection.title)
      expect(header).to_not have_content(collection.description)
      expect(header).to have_content(new_title)
      expect(header).to have_content(new_description)
      expect(page).to have_content(creators.first)
    end
  end

  describe "Removing a file from a collection" do
    let!(:collection) do
      Collection.create(title: 'collection title', description: 'collection description',
                        members: [work1, work2]) { |c| c.apply_depositor_metadata(user.user_key) }
    end

    before do
      sign_in user
      visit "/collections/#{collection.id}/edit"
    end

    it "is successful" do
      within("#document_#{work1.id}") do
        first('button.dropdown-toggle').click
        click_button('Remove from Collection')
      end
      expect(page).to have_content(collection.title)
      expect(page).to have_content(collection.description)
      expect(page).not_to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end
  end

  describe "Removing all files from a collection" do
    let!(:collection) do
      Collection.create(title: 'collection title', description: 'collection description',
                        members: [work1, work2]) { |c| c.apply_depositor_metadata(user.user_key) }
    end

    before do
      sign_in user
      visit "/collections/#{collection.id}/edit"
    end

    it "is successful", :js do
      first('input#check_all').click
      click_button('Remove From Collection')
      expect(page).to have_content(collection.title)
      expect(page).to have_content(collection.description)
      expect(page).not_to have_content(work1.title.first)
      expect(page).not_to have_content(work2.title.first)
    end
  end

  describe 'show pages of a collection' do
    let(:works) do
      (0..12).map do |x|
        GenericWork.create(title: ["title #{x}"]) do |f|
          f.apply_depositor_metadata(user.user_key)
        end
      end
    end

    before { sign_in user }

    let!(:collection) do
      Collection.create(title: 'collection title', description: 'collection description',
                        members: works) { |c| c.apply_depositor_metadata(user.user_key) }
    end

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit '/dashboard/collections'
      expect(page).to have_content(collection.title)
      within('#document_' + collection.id) do
        click_link("Display all details of collection title")
      end
      expect(page).to have_css(".pager")
    end
  end
end
