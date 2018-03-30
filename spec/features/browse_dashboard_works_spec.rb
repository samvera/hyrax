RSpec.describe "Browse Dashboard", type: :feature do
  let(:user) { create(:user) }
  let!(:dissertation) do
    create(:public_work, user: user, title: ["Fake PDF Title"], subject: %w[lorem ipsum dolor sit amet])
  end
  let!(:mp3_work) do
    create(:public_work, user: user, title: ["Test Document MP3"], subject: %w[consectetur adipisicing elit])
  end

  let!(:collection) { create(:public_collection, title: ['Collection with Work'], user: user, create_access: true) }
  let!(:admin_user) { create(:admin) }
  let!(:adminset) { create(:admin_set, title: ['Admin Set with Work'], creator: [admin_user.user_key], with_permission_template: true) }

  before do
    # Grant the user access to deposit into an admin set.
    create(:permission_template_access,
           :deposit,
           permission_template: create(:permission_template, with_admin_set: true),
           agent_type: 'user',
           agent_id: user.user_key)

    sign_in user

    create(:public_work,
           user: user,
           title: ["Fake Wav Files"],
           subject: %w[sed do eiusmod tempor incididunt ut labore],
           admin_set: adminset,
           member_of_collections: [collection])
    visit "/dashboard/my/works"
  end

  it "lets the user search and display their files" do
    fill_in "q", with: "PDF"
    click_button "search-submit-header"
    expect(page).to have_content("Fake PDF Title")
    within(".constraints-container") do
      expect(page).to have_content("Filtering by:")
      expect(page).to have_css("span.glyphicon-remove")
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
      expect(page).to have_content("Edit Work")
    end
  end

  it "allows me to delete works in upload_sets", js: true do
    first('input#check_all').click
    expect do
      accept_confirm { click_button('Delete Selected') }
      expect(page).to have_content('Batch delete complete')
    end.to change { GenericWork.count }.by(-3)
  end

  it "has a Collection facet that includes collections and admin sets", js: true do
    click_button "Collection"
    expect(page).to have_link('Admin Set with Work')
    expect(page).to have_link('Collection with Work')
  end
end
