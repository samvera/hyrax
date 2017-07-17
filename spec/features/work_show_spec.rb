describe "display a work as its owner" do
  let(:work_path) { "/concern/generic_works/#{work.id}" }
  before do
    create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
  end

  context "as the work owner" do
    let(:work) do
      create(:work_with_one_file,
             with_admin_set: true,
             title: ["Magnificent splendor"],
             source: ["The Internet"],
             based_near: ["USA"],
             user: user)
    end
    let(:user) { create(:user) }
    before do
      sign_in user
      visit work_path
    end

    it "shows a work" do
      expect(page).to have_selector 'h1', text: 'Magnificent splendor'
      expect(page).to have_selector 'li', text: 'The Internet'
      expect(page).to have_selector 'th', text: 'Location'
      expect(page).not_to have_selector 'th', text: 'Based near'

      # Displays FileSets already attached to this work
      within '.related-files' do
        expect(page).to have_selector '.filename', text: 'A Contained FileSet'
      end
    end
  end

  context "as a user who is not logged in" do
    let(:work) { create(:public_generic_work, title: ["Magnificent splendor"], source: ["The Internet"], based_near: ["USA"]) }
    before do
      visit work_path
    end

    it "shows a work" do
      expect(page).to have_selector 'h1', text: 'Magnificent splendor'
      expect(page).to have_selector 'li', text: 'The Internet'
      expect(page).to have_selector 'th', text: 'Location'
      expect(page).not_to have_selector 'th', text: 'Based near'

      # Doesn't have the upload form for uploading more files
      expect(page).not_to have_selector "form#fileupload"

      # has some social media buttons
      expect(page).to have_link '', href: "https://twitter.com/intent/tweet/?text=Magnificent+splendor&url=http%3A%2F%2Fwww.example.com%2Fconcern%2Fgeneric_works%2F#{work.id}"

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
