RSpec.describe 'collection', type: :feature do
  let(:user) { create(:user) }

  let(:collection1) { create(:public_collection, user: user) }
  let(:collection2) { create(:public_collection, user: user) }

  describe 'collection show page' do
    let(:collection) do
      create(:public_collection, user: user, description: ['collection description'])
    end
    let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection], user: user) }

    before do
      sign_in user
      visit "/collections/#{collection.id}"
    end

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      # Should not show title and description a second time
      expect(page).not_to have_css('.metadata-collections', text: collection.title.first)
      expect(page).not_to have_css('.metadata-collections', text: collection.description.first)
      # Should not have Collection Descriptive metadata table
      expect(page).to have_content("Descriptions")
      # Should have search results / contents listing
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      expect(page).not_to have_css(".pager")

      click_link "Gallery"
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end

    it "hides collection descriptive metadata when searching a collection" do
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      fill_in('collection_search', with: work1.title.first)
      click_button('collection_submit')
      # Should not have Collection metadata table (only title and description)
      expect(page).not_to have_content("Total works")
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      # Should have search results / contents listing
      expect(page).to have_content("Search Results")
      expect(page).to have_content(work1.title.first)
      expect(page).not_to have_content(work2.title.first)
    end
  end

  # TODO: this is just like the block above. Merge them.
  describe 'show pages of a collection' do
    before do
      docs = (0..12).map do |n|
        { "has_model_ssim" => ["GenericWork"], :id => "zs25x871q#{n}",
          "depositor_ssim" => [user.user_key],
          "suppressed_bsi" => false,
          "member_of_collection_ids_ssim" => [collection.id],
          "edit_access_person_ssim" => [user.user_key] }
      end
      ActiveFedora::SolrService.add(docs, commit: true)

      sign_in user
    end
    let(:collection) { create(:named_collection, user: user) }

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit "/collections/#{collection.id}"
      expect(page).to have_css(".pager")
    end
  end
end
