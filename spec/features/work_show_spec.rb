RSpec.describe "display a work as its owner" do
  include Selectors::Dashboard

  let(:work_path) { "/concern/generic_works/#{work.id}" }

  before do
    create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
  end

  context "as the work owner" do
    let(:work) do
      create(:work,
             with_admin_set: true,
             title: ["Magnificent splendor", "Happy little trees"],
             source: ["The Internet"],
             based_near: ["USA"],
             user: user,
             ordered_members: [file_set],
             representative_id: file_set.id)
    end
    let(:user) { create(:user) }
    let(:file_set) { create(:file_set, user: user, title: ['A Contained FileSet'], content: file) }
    let(:file) { File.open(fixture_path + '/world.png') }
    let(:multi_membership_type_1) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 1') }
    let!(:collection) { create(:collection_lw, user: user, collection_type_gid: multi_membership_type_1.gid) }

    before do
      sign_in user
      visit work_path
    end

    it "shows a work" do
      expect(page).to have_selector 'h2', text: 'Magnificent splendor'
      expect(page).to have_selector 'h2', text: 'Happy little trees'
      expect(page).to have_selector 'li', text: 'The Internet'
      expect(page).to have_selector 'dt', text: 'Location'
      expect(page).not_to have_selector 'dt', text: 'Based near'
      expect(page).to have_selector 'button', text: 'Attach Child', count: 1

      # Displays FileSets already attached to this work
      within '.related-files' do
        expect(page).to have_selector '.attribute-filename', text: 'A Contained FileSet'
      end

      # IIIF manifest does not include locale query param
      expect(find('div.viewer:first')['data-uri']).to eq "/concern/generic_works/#{work.id}/manifest"
    end

    it "add work to a collection", clean_repo: true, js: true do
      optional 'ability to get capybara to find css select2-result (see Issue #3038)' if ENV['TRAVIS']
      click_button "Add to collection" # opens the modal
      select_member_of_collection(collection)
      click_button 'Save changes'

      # forwards to collection show page
      expect(page).to have_content collection.title.first
      expect(page).to have_content work.title.first
      expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
    end
  end

  context "as a user who is not logged in" do
    let(:work) { create(:public_generic_work, title: ["Magnificent splendor"], source: ["The Internet"], based_near: ["USA"]) }
    let(:page_title) { { text: "Generic Work | Magnificent splendor | ID: #{work.id} | Hyrax" }.to_param }

    before do
      visit work_path
    end

    it "shows a work" do
      expect(page).to have_selector 'h2', text: 'Magnificent splendor'
      expect(page).to have_selector 'li', text: 'The Internet'
      expect(page).to have_selector 'dt', text: 'Location'
      expect(page).not_to have_selector 'dt', text: 'Based near'

      # Doesn't have the upload form for uploading more files
      expect(page).not_to have_selector "form#fileupload"

      # has some social media buttons
      expect(page).to have_link '', href: "https://twitter.com/intent/tweet/?#{page_title}&url=http%3A%2F%2Fwww.example.com%2Fconcern%2Fgeneric_works%2F#{work.id}"

      # exports EndNote
      expect(page).to have_link 'EndNote'
      click_link 'EndNote'
      expect(page).to have_content '%0 Generic Work'
      expect(page).to have_content '%T Magnificent splendor'
      expect(page).to have_content '%R http://localhost/files/'
      expect(page).to have_content '%~ Hyrax'
      expect(page).to have_content '%W Institution'
    end
  end
end
