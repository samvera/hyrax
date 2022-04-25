# frozen_string_literal: true
RSpec.describe 'searching' do
  let(:user) { create :user }
  let(:subject_value) { 'mustache' }
  let!(:work) do
    create(:public_work,
           title: ["Toothbrush"],
           keyword: [subject_value, 'taco'],
           user: user)
  end

  let!(:collection) do
    create(:public_collection_lw, title: ['collection title abc'], description: [subject_value], user: user, members: [work])
  end

  context "as a public user", :clean_repo do
    it "using the gallery view" do
      visit '/'
      fill_in "search-field-header", with: "Toothbrush"
      click_button "search-submit-header"
      expect(page).to have_content "1 entry found"
      within "#search-results" do
        expect(page).to have_content "Toothbrush"
      end

      click_link "Gallery"
      within "#documents" do
        expect(page).to have_content "Toothbrush"
      end
    end

    it "only searches all and does not display search options for dashboard files" do
      visit '/'

      # it "does not display search options for dashboard files" do
      # This section was tested on its own, and required a full setup.
      within(".input-group-append") do
        expect(page).not_to have_content("All")
        expect(page).not_to have_content("My Works")
        expect(page).not_to have_content("My Collections")
        expect(page).not_to have_content("My Shares")
      end

      expect(page).not_to have_css("a[data-search-label*=All]", visible: false)
      expect(page).not_to have_css("a[data-search-label*='My Works']", visible: false)
      expect(page).not_to have_css("a[data-search-label*='My Collections']", visible: false)
      expect(page).not_to have_css("a[data-search-label*='My Highlights']", visible: false)
      expect(page).not_to have_css("a[data-search-label*='My Shares']", visible: false)

      fill_in "search-field-header", with: subject_value
      click_button("Go")

      expect(page).to have_content('Search Results')
      expect(page).to have_content "Toothbrush"
      expect(page).to have_content('collection title abc')
      expect(page).to have_selector("//img")

      expect(page.body).to include "<span itemprop=\"keywords\">taco</span> and <span itemprop=\"keywords\">mustache</span>"
    end
  end
end
