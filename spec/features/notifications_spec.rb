require 'spec_helper'

describe "Notifications page" do

  before do
    sign_in FactoryGirl.create(:user_with_mail)
  end

  it "should list notifications with date, subject and message" do
    visit "/notifications"
    page.should have_content "User Notifications"
    page.find(:xpath, '//thead/tr').should have_content "Date"
    page.find(:xpath, '//thead/tr').should have_content "Subject"
    page.find(:xpath, '//thead/tr').should have_content "Message"
    page.should have_content "Sample notification 1."
    page.should have_content "less than a minute ago"
    page.should have_content "You've got mail."
  end

end
