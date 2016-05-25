describe "Browse Dashboard", type: :feature do
  let(:user) { FactoryGirl.create(:user) }
  let!(:dissertation) { FactoryGirl.create(:public_work, user: user, title: ["Fake PDF Title"], subject: %w(lorem ipsum dolor sit amet)) }
  let!(:mp3_work) { FactoryGirl.create(:public_work, user: user, title: ["Test Document MP3"], subject: %w(consectetur adipisicing elit)) }
  let!(:audio_work) { FactoryGirl.create(:public_work, user: user, title: ["Fake Wav Files"], subject: %w(sed do eiusmod tempor incididunt ut labore)) }

  before do
    sign_in user
    visit "/dashboard"
  end

  it "lets the user search and display their files" do
    expect(page).to have_link "Create Collection"
    expect(page).to have_link "Create Work"

    # Search
    fill_in "q", with: "PDF"
    click_button "search-submit-header"
    expect(page).to have_content("Fake PDF Title")

    visit "/dashboard/works"
    fill_in "q", with: "PDF"
    click_button "search-submit-header"
    expect(page).to have_content("Fake PDF Title")
    within(".constraints-container") do
      expect(page).to have_content("You searched for:")
      expect(page).to have_css("span.glyphicon-remove")
      find(".dropdown-toggle").click
    end
    expect(page).to have_content("Fake Wav File")

    # Browse facets
    click_link "Subject"
    click_link "more Subjects"
    click_link "consectetur"

    within("#document_#{mp3_work.id}") do
      expect(page).to have_link("Display all details of Test Document MP3",
                                href: curation_concerns_generic_work_path(mp3_work))
    end
    click_link("Remove constraint Subject: consectetur")

    # Refresh the page
    click_button "Refresh"
    within("#document_#{dissertation.id}") do
      click_button("Select an action")
      expect(page).to have_content("Edit Work")
    end

    # View other tabs
    ["My Collections", "My Highlights", "Files Shared with Me"].each do |tab|
      within("#my_nav") do
        click_link(tab)
      end
      expect(page).to have_content(tab)
    end
  end

  it "allows me to delete works in upload_sets", js: true do
    visit "/dashboard/works"
    first('input#check_all').click
    expect {
      click_button('Delete Selected')
    }.to change { GenericWork.count }.by(-3)
  end
end
