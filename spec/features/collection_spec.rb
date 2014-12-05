require 'spec_helper'

describe 'collection', :type => :feature do
  def create_collection(title, description)
    visit '/dashboard'
    first('#hydra-collection-add').click
    expect(page).to have_content 'Create New Collection'
    fill_in('Title', with: title)
    fill_in('Abstract or Summary', with: description)
    click_button("Create Collection")
    expect(page).to have_content 'Items in this Collection'
    expect(page).to have_content title
    expect(page).to have_content description
  end

  let(:title1) {"Test Collection 1"}
  let(:description1) {"Description for collection 1 we are testing."}
  let(:title2) {"Test Collection 2"}
  let(:description2) {"Description for collection 2 we are testing."}

  let(:user) { FactoryGirl.find_or_create(:archivist) }

  before do
    @gfs = []
    (0..1).each do |x|
      @gfs[x] =  GenericFile.new(title: ["title #{x}"]).tap do |f|
        f.apply_depositor_metadata(user.user_key)
        f.save!
      end
    end
    @gf1 = @gfs[0]
    @gf2 = @gfs[1]
  end

  describe 'create collection' do
    before do
      sign_in user
    end

    it "should create collection from the dashboard and include files", js: true do
      create_collection(title2, description2)
      visit '/dashboard/files'
      first('input#check_all').click
      click_button "Add to Collection" # opens the modal
      # since there is only one collection, it's not necessary to choose a radio button
      click_button "Update Collection"
      expect(page).to have_content "Items in this Collection"
      # There are two rows in the table per document (one for the general info, one for the details)
      # Make sure we have at least 2 documents
      expect(page).to have_selector "table.table-zebra-striped tr#document_#{@gf1.id}"
      expect(page).to have_selector "table.table-zebra-striped tr#document_#{@gf2.id}"
    end
  end

  describe 'delete collection' do
    before do
      @collection = Collection.new title:'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user.user_key)
      @collection.save
      sign_in user
      visit '/dashboard/collections'
    end

    it "should delete a collection" do
      expect(page).to have_content(@collection.title)
      within('#document_'+@collection.noid) do
        first('button.dropdown-toggle').click
        first(".itemtrash").click
      end
      expect(page).not_to have_content(@collection.title)
    end
  end

  describe 'show collection' do
    before do
      @collection = Collection.new title: 'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user.user_key)
      @collection.members = [@gf1,@gf2]
      @collection.save
      sign_in user
      visit '/dashboard/collections'
    end

    it "should show a collection with a listing of Descriptive Metadata and catalog-style search results" do
      expect(page).to have_content(@collection.title)
      within('#document_'+@collection.noid) do
        click_link("Display all details of collection title")
      end
      expect(page).to have_content(@collection.title)
      expect(page).to have_content(@collection.description)
      # Should not show title and description a second time
      expect(page).to_not have_css('.metadata-collections', text: @collection.title)
      expect(page).to_not have_css('.metadata-collections', text: @collection.description)
      # Should not have Collection Descriptive metadata table
      expect(page).to have_content("Descriptions")
      # Should have search results / contents listing
      expect(page).to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
      expect(page).to_not have_css(".pager")

      click_link "Gallery"
      expect(page).to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
    end

    it "should hide collection descriptive metadata when searching a collection" do
      # URL: /dashboard/collections
      expect(page).to have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        click_link("Display all details of collection title")
      end
      # URL: /collections/collection-id
      expect(page).to have_content(@collection.title)
      expect(page).to have_content(@collection.description)
      expect(page).to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
      fill_in('collection_search', with: @gf1.title.first)
      click_button('collection_submit')
      # Should not have Collection metadata table (only title and description)
      expect(page).to_not have_content("Total Items")
      expect(page).to have_content(@collection.title)
      expect(page).to have_content(@collection.description)
      # Should have search results / contents listing
      expect(page).to have_content("Search Results")
      expect(page).to have_content(@gf1.title.first)
      expect(page).to_not have_content(@gf2.title.first)
    end
  end

  describe 'edit collection' do
    before do
      @collection = Collection.new(title: 'collection title')
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user.user_key)
      @collection.members = [@gf1, @gf2]
      @collection.save
      sign_in user
      visit '/dashboard/collections'
    end

    it "should edit and update collection metadata" do
      # URL: /dashboard/collections
      expect(page).to have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        find('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      # URL: /collections/collection-id/edit
      expect(page).to have_field('collection_title', with: @collection.title)
      expect(page).to have_field('collection_description', with: @collection.description)
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
      expect(header).to_not have_content(@collection.title)
      expect(header).to_not have_content(@collection.description)
      expect(header).to have_content(new_title)
      expect(header).to have_content(new_description)
      expect(page).to have_content(creators.first)
    end

    it "should remove a file from a collection" do
      expect(page).to have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        first('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      expect(page).to have_field('collection_title', with: @collection.title)
      expect(page).to have_field('collection_description', with: @collection.description)
      expect(page).to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
      within("#document_#{@gf1.noid}") do
        first('button.dropdown-toggle').click
        click_button('Remove from Collection')
      end
      expect(page).to have_content(@collection.title)
      expect(page).to have_content(@collection.description)
      expect(page).not_to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
    end

    it "should remove all files from a collection", js: true do
      expect(page).to have_content(@collection.title)
      within('#document_'+@collection.noid) do
        first('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      expect(page).to have_field('collection_title', with: @collection.title)
      expect(page).to have_field('collection_description', with: @collection.description)
      expect(page).to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
      first('input#check_all').click
      click_button('Remove From Collection')
      expect(page).to have_content(@collection.title)
      expect(page).to have_content(@collection.description)
      expect(page).not_to have_content(@gf1.title.first)
      expect(page).not_to have_content(@gf2.title.first)
    end
  end

  describe 'show pages of a collection' do
    before do
      (2..12).each do |x|
        @gfs[x] =  GenericFile.new(title: ["title #{x}"]).tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save!
        end
      end
      @collection = Collection.new title: 'collection title', description: 'collection description'
      @collection.apply_depositor_metadata(user.user_key)
      @collection.members = @gfs
      @collection.save!
      sign_in user
      visit '/dashboard/collections'
    end

    it "should show a collection with a listing of Descriptive Metadata and catalog-style search results" do
      expect(page).to have_content(@collection.title)
      within('#document_'+@collection.noid) do
        click_link("Display all details of collection title")
      end
      expect(page).to have_css(".pager")
    end
  end
end
