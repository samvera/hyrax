require 'spec_helper'

describe "Browse files", :type => :feature do

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
  end

  before do
    @fixtures = find_or_create_file_fixtures
    @fixtures[0].tag = ["key"]
    (1..25).each do |i|
      @fixtures[0].tag << "key_#{i}"
    end
    @fixtures[1].tag = ["key"]
    @fixtures[0].save
    (1..20).each do |i|
      @fixtures[1].tag << "key_#{i}"
    end
    @fixtures[1].save
  end

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    visit '/'
    fill_in "search-field-header", with: "key"
    click_button "search-submit-header"
    click_link "Keyword"
    click_link "more Keywords»"
    expect(page).to have_css "h3", text: "Keyword"
  end

  describe "when not logged in" do
    it "should let us browse some of the fixtures" do
      click_link "18"
      expect(page).to have_content "Search Results"
      expect(page).to have_css "a", text: @fixtures[0].title[0]
      click_link @fixtures[0].title[0]
      expect(page).to have_content "Download"
      expect(page).not_to have_content "Edit"
    end
    it "should allow you to click next" do
      expect(page).to have_content "Numerical Sort"
      expect(page).to have_css "a.sort_change", text:"Numerical Sort"
      click_link "Numerical Sort"
      within(".modal-body") do
        expect(page).to have_content "key_1 "
        expect(page).not_to have_content "key_25 "
      end
      click_link 'Next »'
      expect(page).to have_css "a.btn-link", text:"« Previous", wait: Capybara.default_wait_time*4
      within(".modal-body") do
        expect(page).to have_content "key_25 "
        expect(page).not_to have_content "key_1 "
      end
    end
  end
end
