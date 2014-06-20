require 'spec_helper'

describe "Browse files" do

  before do
    allow(User).to receive(:find_by_user_key).and_return(stub_model(User, twitter_handle: 'bob'))
  end

  before(:all) do
    @fixtures = find_or_create_file_fixtures
    @fixtures[0].tag = "key"
    (1..25).each do |i|
      @fixtures[0].tag << i
    end
    @fixtures[0].save
  end

  before do
    visit '/'
    fill_in "search-field-header", with: "key"
    click_button "search-submit-header"
    click_link "more Keywords"
  end

  describe "when not logged in" do
    it "should let us browse some of the fixtures" do
      click_link "18"
      page.should have_content "Search Results"
      click_link @fixtures[0].title[0]
      page.should have_content "Download"
      page.should_not have_content "Edit"
    end
    it "should allow you to click next" do
      first(:link, 'Next').click
      page.should have_content "5"
      page.should_not have_content "11"
    end
  end
end
