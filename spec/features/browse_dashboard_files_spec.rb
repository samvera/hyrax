require 'spec_helper'

describe "Browse Dashboard files" do

  before do
    @fixtures = find_or_create_file_fixtures
    sign_in FactoryGirl.create :user_with_fixtures
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
    click_link "dashboard"
    click_link "more Subjects"
    click_link "consectetur"
    within("#document_#{@fixtures[1].noid}") do
      click_link "Test Document MP3.mp3"
    end
    page.should have_content "File Details"
  end

  it "should allow me to edit files (from the fixtures)" do
    click_link "dashboard"
    fill_in "dashboard_search", with: "Wav"
    click_button "dashboard_submit"
    click_link "Edit File"
    page.should have_content "Edit Fake Wav File.wav"
  end

end
