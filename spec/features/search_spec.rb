require 'spec_helper'

describe 'searching' do
  let!(:work) {
    GenericWork.new.tap do |work|
      work.title = ["Toothbrush"]
      work.apply_depositor_metadata('Frodo')
      work.read_groups = ['public']
      work.save!
    end
  }

  context "as a public user" do
    it "using the gallery view" do
      visit '/'
      fill_in "search-field-header", with: "Toothbrush"
      click_button "search-submit-header"
      expect(page).to have_content "1 entry found"
      within "#search-results" do
        expect(page).to have_content "Toothbrush"
      end
      
      click_link "Gallery"
      expect(page).to have_content "You searched for: Toothbrush"
      within "#documents" do
        expect(page).to have_content "Toothbrush"
      end
    end

    it "should not display search options for dashboard files" do
      visit "/"
      within(".input-group-btn") do
        expect(page).to_not have_content("My Files")
        expect(page).to_not have_content("My Collections")
        expect(page).to_not have_content("My Shares")
      end
    end

  end
end
