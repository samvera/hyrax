require 'spec_helper'

describe "Uploading files via web form" do

  before do
    sign_in :user_with_fixtures
  end

  it "should have an ingest screen" do
    visit "/notifications"
    page.should have_content "User Notifications"
    page.find(:xpath, '//thead/tr').should have_content "Date"
    page.find(:xpath, '//thead/tr').should have_content "Subject"
    page.find(:xpath, '//thead/tr').should have_content "Message"
    page.should have_content "Sample notification."
    page.should have_content "less than a minute ago"
    page.should have_content "You've got mail."
  end

end
