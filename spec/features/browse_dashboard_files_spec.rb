require 'spec_helper'

describe "Browse Dashboard files" do

  before do
    find_or_create_file_fixtures
    sign_in :user_with_fixtures
  end

  it "should show me some files (from the fixtures)" do
    click_link "dashboard"
    page.should have_content "Edit File"
    page.should have_content "Download File"
    fill_in "dashboard_search", with: "PDF"
    click_button "dashboard_submit"
    page.should have_content "Fake Document Title"
  end

  it "should allow you to browse facets" do
    # TODO: fix more facets link!
    pending "Until more facets link is fixed..."
    visit '/'
    click_link "more Subjects"
    click_link "consectetur"
    #page.should have_content "1 - 5 of 5"
    click_link "Test Document MP3.mp3"
    page.should have_content "Download"
    page.should_not have_content "Edit"
  end

  it "should allow me to edit files (from the fixtures)" do
    click_link "dashboard"
    fill_in "dashboard_search", with: "Wav"
    click_button "dashboard_submit"
    click_link "Edit File"
    page.should have_content "Edit Fake Wav File.wav"
  end

end
