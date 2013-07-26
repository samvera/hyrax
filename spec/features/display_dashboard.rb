require 'spec_helper'

describe "Display Dashboard files" do

  before do
    sign_in :user
  end

  it "should display the dashboard and have search" do
    click_link 'dashboard'
    fill_in "dashboard_search", with: "dash search"
    click_button "dashboard_submit"
    page.should have_content "Dashboard"
    page.should have_content "You searched for: dash search"
    find_field("search-field-header").value.should be_nil
  end

  it "should display the dashboard and want to upload files" do
    click_link 'dashboard'
    click_link 'Upload File(s)'
    page.should have_content "Upload"
  end

  it "should display the dashboard and want to upload files" do
    click_link 'dashboard'
    click_link 'Upload File(s)'
    page.should have_content "Upload"
  end

  it "should display the dashboard and want to search the whole system" do
    fill_in "search-field-header", with: "system search"
    click_button "search-submit-header"
    page.should have_content "You searched for: system search"
    page.should_not have_content "Dashboard"
    find_field("search-field-header").value.should match(/system search/)
  end

  # @culerity
  # Scenario: I have files on my dashboard I should see icons 
  #   #Given I load sufia fixtures
  #   And I am logged in as "archivist1@example.com"
  #   And I follow "dashboard"
  #   Then I should see "Test Document Text"
  #   When I follow the link within "a[href='/files/test3'].itemtrash"
  #   Then I should see "The file has been deleted"
end
