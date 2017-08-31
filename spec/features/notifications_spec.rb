RSpec.feature "Notifications page", type: :feature do
  before do
    sign_in FactoryGirl.create(:user_with_mail)
    visit "/notifications"
  end

  it "lists notifications with date, subject and message" do
    page.assert_text "Notifications"
    expect(page).to have_selector "table.datatable"
    page.find(:xpath, '//thead/tr').assert_text "Date"
    page.find(:xpath, '//thead/tr').assert_text "Subject"
    page.find(:xpath, '//thead/tr').assert_text "Message"
    page.assert_text "These files could not be updated. You do not have sufficient privileges to edit them. "
    page.assert_text "These files have been saved"
    page.assert_text "File 1 could not be updated. You do not have sufficient privileges to edit it."
    page.assert_text "File 1 has been saved"
    page.assert_text "Batch upload permission denied  "
    page.assert_text "Batch upload complete"
  end
end
