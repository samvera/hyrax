require 'spec_helper'

describe "Browse Dashboard", type: :feature do
  let(:user) { FactoryGirl.create(:user) }

  let!(:dissertation) { FactoryGirl.create(:public_work, user: user, title: ["Fake PDF Title"], subject: %w(lorem ipsum dolor sit amet)) }

  let!(:mp3_work) { FactoryGirl.create(:public_work, user: user, title: ["Test Document MP3"], subject: %w(consectetur adipisicing elit)) }

  let!(:audio_work) { FactoryGirl.create(:public_work, user: user, title: ["Fake Wav Files"], subject: %w(sed do eiusmod tempor incididunt ut labore)) }

  before do
    sign_in user
  end

  it "searches your files by default" do
    visit "/dashboard"
    fill_in "q", with: "PDF"
    click_button "search-submit-header"
    expect(page).to have_content("Fake PDF Title")
  end

  it 'has buttons for user actions' do
    expect(page).to have_link("Create Collection")
    expect(page).to have_link("Upload")
  end

  context "within my files page" do
    before do
      visit "/dashboard/files"
    end

    it "allows you to search your own works and remove constraints" do
      fill_in "q", with: "PDF"
      click_button "search-submit-header"
      expect(page).to have_content("Fake PDF Title")
      within(".constraints-container") do
        expect(page).to have_content("You searched for:")
        expect(page).to have_css("span.glyphicon-remove")
        find(".dropdown-toggle").click
      end
      expect(page).to have_content("Fake Wav File")
    end

    it "allows you to browse facets" do
      click_link "Subject"
      click_link "more Subjects"
      click_link "consectetur"

      within("#document_#{mp3_work.id}") do
        expect(page).to have_link("Display all details of Test Document MP3", href: sufia.generic_work_path(mp3_work))
      end
    end

    it "refreshes the page" do
      # TODO: this would make a good view test.
      click_button "Refresh"
      within("#document_#{dissertation.id}") do
        click_button("Select an action")
        expect(page).to have_content("Edit Work")
      end
    end

    it "allows me to delete works in upload_sets", js: true do
      first('input#check_all').click
      expect {
        click_button('Delete Selected')
      }.to change { GenericWork.count }.by(-3)
    end

    it "links to my other tabs" do
      # TODO: this would make a good view test.
      ["My Collections", "My Highlights", "Files Shared with Me"].each do |tab|
        within("#my_nav") do
          click_link(tab)
        end
        expect(page).to have_content(tab)
      end
    end
  end
end
