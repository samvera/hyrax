require 'spec_helper'

describe 'collection' do
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
  let(:user_key) { user.user_key }

  before(:all) do
    @old_resque_inline_value = Resque.inline
    Resque.inline = true

    @gfs = []
    (0..12).each do |x|
      @gfs[x] =  GenericFile.new.tap do |f|
        f.title = ["title #{x}"]
        f.apply_depositor_metadata('archivist1@example.com')
        f.save!
      end
    end
    @gf1 = @gfs[0]
    @gf2 = @gfs[1]
  end

  after(:all) do
    Resque.inline = @old_resque_inline_value
    Batch.destroy_all
    GenericFile.destroy_all
    Collection.destroy_all
  end

  describe 'create collection' do
    before do
      sign_in user
      visit '/dashboard/collections'
    end
    it "should create collection from the dashboard and include files", js: true do
      create_collection(title2, description2)
      visit '/dashboard/files'
      first('input#check_all').click
      click_button "Add to Collection" # opens the modal
      # since there is only one collection, it's not necessary to choose a radio button
      click_button "Update Collection"
      expect(page).to have_content "Items in this Collection"
      expect(page).to have_selector "ol.catalog li:nth-child(9)" # at least 9 files in this collection
    end
  end

  describe 'delete collection' do
    before (:each) do
      @collection = Collection.new title:'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.save
      sign_in user
      visit '/dashboard/collections'
    end

    it "should delete a collection" do
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        first('button.dropdown-toggle').click
        first(".itemtrash").click
      end
      page.should_not have_content(@collection.title)
    end
  end

  describe 'show collection' do
    before do
      @collection = Collection.new title: 'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.members = [@gf1,@gf2]
      @collection.save
      sign_in user
      visit '/dashboard/collections'
    end

    it "should show a collection with a listing of Descriptive Metadata and catalog-style search results" do
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        click_link("collection title")
      end
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      # Should not have Collection Descriptive metadata table
      page.should have_content("Descriptions")
      # Should have search results / contents listing
      page.should have_content(@gf1.title.first)
      page.should have_content(@gf2.title.first)
      page.should_not have_css(".pager")

      click_link "Gallery"
      expect(page).to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
    end

    it "should hide collection descriptive metadata when searching a collection" do
      page.should have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        click_link("collection title")
      end
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      page.should have_content(@gf1.title.first)
      page.should have_content(@gf2.title.first)
      fill_in('collection_search', with: @gf1.title.first)
      click_button('collection_submit')
      # Should not have Collection Descriptive metadata table
      page.should_not have_content("Descriptions")
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      # Should have search results / contents listing
      page.should have_content(@gf1.title.first)
      page.should_not have_content(@gf2.title.first)
      # Should not have Dashboard content in contents listing
      page.should_not have_content("Visibility")
    end
  end

  describe 'edit collection' do
    before (:each) do
      @collection = Collection.new(title: 'collection title')
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.members = [@gf1, @gf2]
      @collection.save
      sign_in user
      visit '/dashboard/collections'
    end

    it "should edit and update collection metadata" do
      page.should have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        find('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      page.should have_field('collection_title', with: @collection.title)
      page.should have_field('collection_description', with: @collection.description)
      new_title = "Altered Title"
      new_description = "Completely new Description text."
      creators = ["Dorje Trollo", "Vajrayogini"]
      fill_in('Title', with: new_title)
      fill_in('Abstract or Summary', with: new_description)
      fill_in('Creator', with: creators.first)
      within('.primary-actions') do
        click_button('Update Collection')
      end
      page.should_not have_content(@collection.title)
      page.should_not have_content(@collection.description)
      page.should have_content(new_title)
      page.should have_content(new_description)
      page.should have_content(creators.first)
    end

    it "should remove a file from a collection" do
      page.should have_content(@collection.title)
      within("#document_#{@collection.noid}") do
        first('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      page.should have_field('collection_title', with: @collection.title)
      page.should have_field('collection_description', with: @collection.description)
      page.should have_content(@gf1.title.first)
      page.should have_content(@gf2.title.first)
      within("#document_#{@gf1.noid}") do
        first('button.dropdown-toggle').click
        click_button('Remove from Collection')
      end
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      page.should_not have_content(@gf1.title.first)
      page.should have_content(@gf2.title.first)
    end

    it "should remove all files from a collection", js: true do
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        first('button.dropdown-toggle').click
        click_link('Edit Collection')
      end
      page.should have_field('collection_title', with: @collection.title)
      page.should have_field('collection_description', with: @collection.description)
      page.should have_content(@gf1.title.first)
      page.should have_content(@gf2.title.first)
      first('input#check_all').click
      click_button('Remove From Collection')
      page.should have_content(@collection.title)
      page.should have_content(@collection.description)
      page.should_not have_content(@gf1.title.first)
      page.should_not have_content(@gf2.title.first)
    end
  end

  describe 'show pages of a collection' do
    before (:each) do
      @collection = Collection.new title:'collection title'
      @collection.description = 'collection description'
      @collection.apply_depositor_metadata(user_key)
      @collection.members = @gfs
      @collection.save!
      sign_in user
      visit '/dashboard/collections'
    end

    it "should show a collection with a listing of Descriptive Metadata and catalog-style search results" do
      page.should have_content(@collection.title)
      within('#document_'+@collection.noid) do
        click_link("collection title")
      end
      page.should have_css(".pager")
    end
  end
end
