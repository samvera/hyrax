require 'spec_helper'

describe "Notifications page" do

  before do
    sign_in FactoryGirl.create(:user_with_mail)
    visit "/notifications"
  end

  it "should list notifications with date, subject and message" do
    page.should have_content "User Notifications"
    page.find(:xpath, '//thead/tr').should have_content "Date"
    page.find(:xpath, '//thead/tr').should have_content "Subject"
    page.find(:xpath, '//thead/tr').should have_content "Message"
    page.should have_content "These files could not be updated. You do not have sufficient privileges to edit them. "
    page.should have_content "These files have been saved"
    page.should have_content "File 1 could not be updated. You do not have sufficient privileges to edit it."
    page.should have_content "File 1 has been saved"
    page.should have_content "Batch upload permission denied  "
    page.should have_content "Batch upload complete"
  end



end
