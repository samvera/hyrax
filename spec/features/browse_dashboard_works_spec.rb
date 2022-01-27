# frozen_string_literal: true
RSpec.describe "Browse Dashboard", type: :feature do
  let(:user) { create(:user) }
  let!(:dissertation) do
    create(:public_work, user: user, title: ["Fake PDF Title"], subject: %w[lorem ipsum dolor sit amet])
  end
  let!(:mp3_work) do
    create(:public_work, user: user, title: ["Test Document MP3"], subject: %w[consectetur adipisicing elit])
  end

  before do
    # Grant the user access to deposit into an admin set.
    create(:permission_template_access,
           :deposit,
           permission_template: create(:permission_template, with_admin_set: true),
           agent_type: 'user',
           agent_id: user.user_key)

    sign_in user
    create(:public_work, user: user, title: ["Fake Wav Files"], subject: %w[sed do eiusmod tempor incididunt ut labore])
    visit "/dashboard/my/works"
  end

  it "lets the user search and display their files" do
    fill_in "q", with: "PDF"
    click_button "search-submit-header"
    expect(page).to have_content("Fake PDF Title")
    within(".constraints-container") do
      expect(page).to have_content("Filtering by:")
      expect(page).to have_css("span.fa-times")
      find(".dropdown-toggle").click
    end
    expect(page).to have_content("Fake Wav File")

    # Browse facets
    click_button "Status"
    click_link "Published"
    within("#document_#{mp3_work.id}") do
      expect(page).to have_link("Display all details of Test Document MP3",
                                href: hyrax_generic_work_path(mp3_work, locale: 'en'))
    end
    click_link("Remove constraint Status: Published")

    within("#document_#{dissertation.id}") do
      click_button("Select")
      expect(page).to have_css('#action-edit-work')
    end
  end

  it "allows me to delete works in upload_sets", js: true do
    first('input#check_all').click
    expect do
      accept_confirm { click_button('Delete Selected') }
      expect(page).to have_content('Batch delete complete')
    end.to change { GenericWork.count }.by(-3)
  end
end
