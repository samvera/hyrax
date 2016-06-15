describe "Sending an email via the contact form", type: :feature do
  before { sign_in(:user) }

  it "sends mail" do
    visit '/'
    click_link "Contact"
    expect(page).to have_content "Contact Form"
    fill_in "contact_form_name", with: "Test McPherson"
    fill_in "contact_form_email", with: "archivist1@example.com"
    fill_in "contact_form_message", with: "I am contacting you regarding ScholarSphere."
    fill_in "contact_form_subject", with: "My Subject is Cool"
    select "Depositing content", from: "contact_form_category"
    click_button "Send"
    expect(page).to have_content "Thank you for your message!"
  end
end
