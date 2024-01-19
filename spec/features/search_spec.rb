# frozen_string_literal: true

RSpec.shared_examples "search functionality" do |_adapter|
  let(:user) { create :user }
  let(:subject_value) { 'mustache' }
  let!(:work) do
    if Hyrax.config.use_valkyrie?
      FactoryBot.valkyrie_create(:monograph, :public, title: ["Toothbrush"], keyword: [subject_value, 'taco'])
    else
      create(:public_work, title: ["Toothbrush"], keyword: [subject_value, 'taco'], user: user)
    end
  end

  let!(:collection) do
    if Hyrax.config.use_valkyrie?
      FactoryBot.valkyrie_create(:collection_resource, :public, title: ['collection title abc'], creator: user.email, description: [subject_value], members: [work])
    else
      create(:public_collection_lw, title: ['collection title abc'], description: [subject_value], user: user, members: [work])
    end
  end

  before do
    allow(Hyrax.config).to receive(:collection_model).and_return('CollectionResource') if Hyrax.config.use_valkyrie?
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

      find('a.view-type-gallery').click
      expect(page).to have_content "Filtering by: Toothbrush"
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

      expect(page.body).to include "<span itemprop=\"keywords\"><a href=\"/catalog?f%5Bkeyword_sim%5D%5B%5D=taco&amp;locale=en\">taco</a></span>"
      expect(page.body).to include "<span itemprop=\"keywords\"><a href=\"/catalog?f%5Bkeyword_sim%5D%5B%5D=mustache&amp;locale=en\">mustache</a></span>"
    end
  end
end

RSpec.describe 'Searching' do
  context "when Valkyrie is not used" do
    include_examples "search functionality"
  end

  context "when Valkyrie is used" do
    include_examples "search functionality", index_adapter: :solr_index, valkyrie_adapter: :test_adapter
  end
end
