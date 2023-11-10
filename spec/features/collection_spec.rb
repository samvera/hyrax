# frozen_string_literal: true
RSpec.describe 'collection', type: :feature do
  let(:user) { FactoryBot.create(:user) }

  before { sign_in(user) }

  shared_context 'with many indexed members' do
    let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, user: user, title: ['collection title'], description: ['collection description']) }

    before do
      docs = (0..12).map do |n|
        { "has_model_ssim" => [model_name], :id => "zs25x871q#{n}",
          "title_tesim" => ["Test Resource #{n}"],
          "system_modified_dtsi" => Time.new(2023, 11, 2, n).utc,
          "depositor_ssim" => [user.user_key],
          "suppressed_bsi" => false,
          "member_of_collection_ids_ssim" => [collection.id.to_s],
          "nesting_collection__parent_ids_ssim" => [collection.id.to_s],
          "edit_access_person_ssim" => [user.user_key] }
      end
      docs.shuffle!
      Hyrax::SolrService.add(docs, commit: true)
    end
  end

  describe 'collection show page' do
    let(:collection) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 user: user,
                                 description: ['collection description'],
                                 collection_type_gid: collection_type.to_global_id.to_s,
                                 members: [work1, work2, col1, col2])
    end
    let(:collection_type) { FactoryBot.create(:collection_type, :nestable) }
    let(:work1) { FactoryBot.valkyrie_create(:monograph, title: ["King Louie"], read_users: [user]) }
    let(:work2) { FactoryBot.valkyrie_create(:monograph, title: ["King Kong"], read_users: [user]) }
    let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection, title: ["Sub-collection 1"], read_users: [user]) }
    let(:col2) { FactoryBot.valkyrie_create(:hyrax_collection, title: ["Sub-collection 2"], read_users: [user]) }

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit "/collections/#{collection.id}"

      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).to have_content("Collection Details")
      # Should not show title and description a second time
      expect(page).not_to have_css('.metadata-collections', text: collection.title.first)
      expect(page).not_to have_css('.metadata-collections', text: collection.description.first)
      # Should have search results / contents listing
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      expect(page).to have_content(col1.title.first)
      expect(page).to have_content(col2.title.first)
      expect(page).not_to have_css(".pagination")

      click_link "Gallery"
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end

    it "hides collection descriptive metadata when searching a collection" do
      visit "/collections/#{collection.id}"

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

    it "returns json results with correct id and ids" do
      visit "/collections/#{collection.id}.json"

      expect(page).to have_http_status(:success)
      json = JSON.parse(page.body)
      expect(json['id']).to eq collection.id
      expect(json['title']).to match_array collection.title
    end
  end

  context "with a non-nestable collection type" do
    let(:collection) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 user: user,
                                 description: ['collection description'],
                                 collection_type_gid: collection_type.to_global_id.to_s)
    end
    let(:collection_type) { FactoryBot.create(:collection_type, :not_nestable) }

    it "displays basic information on its show page" do
      visit "/collections/#{collection.id}"

      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).to have_content("Collection Details")
    end
  end

  describe 'show work pages of a collection' do
    include_context 'with many indexed members' do
      let(:model_name) { 'Monograph' }
    end

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit "/collections/#{collection.id}"

      expect(page).to have_css(".pagination")

      select('date modified ▲', from: 'Sort')
      click_button 'Refresh'

      expect(page).to have_text(/Test Resource 0.+1.+2.+3.+4.+5.+6.+7.+8.+9/m)
    end
  end

  describe 'show subcollection pages of a collection' do
    include_context 'with many indexed members' do
      let(:model_name) { Hyrax.config.collection_class.to_s }
    end

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit "/collections/#{collection.id}"

      expect(page).to have_css(".pagination")
    end
  end
end
