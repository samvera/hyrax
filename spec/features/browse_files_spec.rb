require 'spec_helper'

describe "Browse files" do

  before(:all) do
    find_or_create_file_fixtures
  end

  describe "when not logged in" do
    it "should let us browse some of the fixtures" do
      visit '/'
      #click_link "more Keywords"
      #click_link "test"
      #page.should have_content "1 - 5 of 5"
      click_link "Fake Document Title"
      page.should have_content "Download"
      page.should_not have_content "Edit"
    end
    it "should allow you to browse facets" do
      # TODO: fix more facets link!
      pending "Until more facets link is fixed..."
      visit '/'
      click_link "more Subjects"
      click_link "consectetur"
      click_link "Test Document MP3.mp3"
      page.should have_content "Download"
      page.should_not have_content "Edit"
    end
  end
end
