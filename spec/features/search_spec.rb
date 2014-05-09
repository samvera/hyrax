require 'spec_helper'

describe 'searching' do
  before { GenericFile.destroy_all }
  let!(:file) { FactoryGirl.create(:public_file, title: "Toothbrush") }
  it "should find the file and have a gallery" do
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
end

