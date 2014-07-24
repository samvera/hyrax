require 'spec_helper'

describe 'catalog searching' do

  before(:all) do
    @gf1 = GenericFile.new.tap do |f|
      f.title = ['title 1']
      f.tag = ["tag1", "tag2"]
      f.apply_depositor_metadata('jilluser')
      f.read_groups = ['public']
      f.save!
    end
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

  after(:all) do
    User.destroy_all
    GenericFile.destroy_all
    Collection.destroy_all
  end

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    sign_in :user
    visit '/'
  end

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

  context "many tags" do
    before do
      (1..25).each do |i|
        @gf1.tag << "tag#{i.to_s}"
      end
      @gf1.save
      within('#masthead_controls') do
        fill_in('search-field-header', with: "tag1")
        click_button("Go")
      end
    end

    it "allows for browsing tags" do
      expect(page).to have_content('Search Results')
      within('#facets') do
        first('a.more_facets_link').click
        click_link "more Keywords»"
      end
      click_link "tag18"
      expect(page).to have_content "Search Results"
      click_link @gf1.title[0]
      expect(page).to have_content "Download"
      expect(page).to_not have_content "Edit"
    end

  end
end
