require 'spec_helper'

describe 'catalog searching', :type => :feature do

  before do
    @gf1 = GenericFile.new.tap do |f|
      f.title = ['title 1']
      f.tag = ["tag1", "tag2"]
      f.apply_depositor_metadata('jilluser')
      f.read_groups = ['public']
      f.save!
    end
  end

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    sign_in :user
    visit '/'
  end

  context "with files and collections" do
    before do
      @gf2 = GenericFile.new.tap do |f|
        f.title = ['title 2']
        f.tag = ["tag2", "tag3"]
        f.apply_depositor_metadata('jilluser')
        f.read_groups = ['public']
        f.save!
      end
      @col = Collection.new.tap do |f|
        f.title = 'title 3'
        f.tag = ["tag3", "tag4"]
        f.apply_depositor_metadata('jilluser')
        f.read_groups = ['public']
        f.save!
      end
    end

    # TODO most of these tests could be controller tests.
    it "finds multiple files" do
      within('#masthead_controls') do
        fill_in('search-field-header', with: "tag2")
        click_button("Go")
      end
      expect(page).to have_content('Search Results')
      expect(page).to have_content(@gf1.title.first)
      expect(page).to have_content(@gf2.title.first)
      expect(page).to_not have_content(@col.title)
    end

    it "finds files and collections" do
      within('#masthead_controls') do
        fill_in('search-field-header', with: "tag3")
        click_button("Go")
      end
      expect(page).to have_content('Search Results')
      expect(page).to have_content(@col.title)
      expect(page).to have_content(@gf2.title.first)
      expect(page).to_not have_content(@gf1.title.first)
    end

    it "finds collections" do
      within('#masthead_controls') do
        fill_in('search-field-header', with: "tag4")
        click_button("Go")
      end
      expect(page).to have_content('Search Results')
      expect(page).to have_content(@col.title)
      expect(page).to_not have_content(@gf2.title.first)
      expect(page).to_not have_content(@gf1.title.first)
    end
  end

  context "many tags" do
    before do
      (1..25).each do |i|
        @gf1.tag += ["tag#{sprintf('%02d', i)}"]
      end
      @gf1.save!
      within('#masthead_controls') do
        fill_in('search-field-header', with: "tag1")
        click_button("Go")
      end
    end

    it "allows for browsing tags" do
      click_link "Keyword"
      click_link "more Keywords»"
      click_link "tag18"
      expect(page).to have_content "Search Results"
      click_link @gf1.title[0]
      expect(page).to have_content "Download"
      expect(page).to_not have_content "Edit"
    end

  end
end
