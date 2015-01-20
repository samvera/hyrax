require 'spec_helper'

describe "Browse files", :type => :feature do

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
  end

  before do
    @fixtures = create_file_fixtures
    @fixtures[0].tag = ["key"]
    (1..25).each do |i|
      @fixtures[0].tag << i.to_s
    end
    @fixtures[0].save
  end

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
    visit '/'
    fill_in "search-field-header", with: "key"
    click_button "search-submit-header"
    click_link "Keyword"
    click_link "more Keywords»"
  end

  describe "when not logged in" do
    it "should let us browse some of the fixtures" do
      click_link "13"
      expect(page).to have_content "Search Results"
      click_link @fixtures[0].title[0]
      expect(page).to have_content "Download"
      expect(page).not_to have_content "Edit"
    end
    it "should allow you to click next" do
      within('.bottom') do
        click_link 'Next »'
      end
      within(".modal-body") do
        expect(page).to have_content "5"
        expect(page).not_to have_content "11"
      end
    end
  end
end
