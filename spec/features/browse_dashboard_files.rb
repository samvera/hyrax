require 'spec_helper'

describe "Browse Dashboard files" do

  before do
    sign_in :user_with_fixtures
  end

  it "should show me some files (from the fixtures)" do
    click_link "dashboard"
    click_link "more Keywords"
    click_link "keyf"
    page.should have_content "Test mp3"
  end

  it "should allow me to edit files (from the fixtures)" do
    click_link "dashboard"
    click_link "Edit File"
    page.should have_content "Edit Test mp3"
  end
end
