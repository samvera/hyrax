require 'spec_helper'

describe "Browse Dashboard" do

  before do
    @fixtures = find_or_create_file_fixtures
    sign_in FactoryGirl.create :user_with_fixtures
  end

  it "should search your files by deafult" do
    visit "/dashboard"
    fill_in "q", with: "PDF"
    click_button "search-submit-header"
    expect(page).to have_content("Fake Document Title")
  end

  context "within my files page" do

    before do
      visit "dashboard/files"
    end

    it "should display all the necessary information" do
      expect(page).to have_content("Edit File")
      expect(page).to have_content("Download File")
      expect(page).to_not have_content("Is part of:")
      first(".label-success") do
        expect(page).to have_content("Open Access")
      end
      expect(page).to have_link("Create Collection")
      expect(page).to have_link("Upload")
    end

    it "should allow you to search your own files and remove constraints" do
      fill_in "q", with: "PDF"
      click_button "search-submit-header"
      expect(page).to have_content("Fake Document Title")
      within(".constraints-container") do
        expect(page).to have_content("You searched for:")
        expect(page).to have_css("span.glyphicon-remove")
        find(".dropdown-toggle").click
      end
      expect(page).to have_content("Fake Wav File")
    end

    it "should allow you to browse facets" do
      click_link "more Subjects"
      click_link "consectetur"
      within("#document_#{@fixtures[1].noid}") do
        click_link "Test Document MP3.mp3"
      end
      expect(page).to have_content("File Details")
    end

    it "should allow me to edit files (from the fixtures)" do
      fill_in "q", with: "Wav"
      click_button "search-submit-header"
      click_button "Select an action"
      click_link "Edit File"
      expect(page).to have_content("Edit Fake Wav File.wav")
    end

    it "should refresh the page of files" do
      click_button "Refresh"
      expect(page).to have_content("Edit File")
      expect(page).to have_content("Download File")
    end

    it "should allow me to edit files in batches" do
      pending "Need to enable javascript testing"
      first('input#check_all').click
      click_button('Edit Selected')
      expect(page).to have_content('3 files')
    end

  end

  context "within my collections page" do
    before do
      visit "dashboard/collections"
    end
    it "should search within my collections" do
      within(".input-group-btn") do
        expect(page).to have_content("My Collections")
      end
    end
  end

  context "within my highlights page" do
    before do
      visit "dashboard/highlights"
    end
    it "should search within my highlights" do
      within(".input-group-btn") do
        expect(page).to have_content("My Highlights")
      end
    end
  end

  context "within my shares page" do
    before do
      visit "dashboard/shares"
    end
    it "should search within my shares" do
      within(".input-group-btn") do
        expect(page).to have_content("My Shares")
      end
    end
  end

end
