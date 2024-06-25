# frozen_string_literal: true
RSpec.describe "work show view" do
  include Selectors::Dashboard

  let(:work_path) { "/concern/generic_works/#{work.id}" }

  # this context was added to section off a new test supporting
  # development in the valkyrie context. It doesn't reflect AF-only
  # functionality; these tests probably still need to be updated to run in the
  # valkyrie context
  context "in ActiveFedora", :active_fedora do
    let(:app_host) { Capybara.app_host || 'http://www.example.com' }

    before do
      allow(Hyrax::Analytics.config).to receive(:analytics_id).and_return('UA-XXXXXXXX')
      FactoryBot.create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
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

      let(:user) { FactoryBot.create(:user) }
      let(:file_set) { FactoryBot.create(:file_set, user: user, title: ['A Contained FileSet'], content: file) }
      let(:file) { File.open(fixture_path + '/world.png') }
      let(:multi_membership_type_1) { FactoryBot.create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 1') }
      let!(:collection) { FactoryBot.create(:collection_lw, user: user, collection_type: multi_membership_type_1) }

      before do
        work.ordered_members << file_set
        work.save!
        sign_in user
        visit work_path
      end

      around do |example|
        Hyrax.config.analytics_reporting = true
        example.run
        Hyrax.config.analytics_reporting = false
      end

      it "shows work content and all editor buttons and links" do
        expect(page).to have_selector 'h1', text: 'Magnificent splendor'
        expect(page).to have_selector 'h1', text: 'Happy little trees'
        expect(page).to have_selector 'li', text: 'The Internet'
        expect(page).to have_selector 'dt', text: 'Location'
        expect(page).not_to have_selector 'dt', text: 'Based near'
        expect(page).to have_selector 'button', text: 'Attach Child', count: 1
        expect(page).to have_link 'Analytics'
        expect(page).to have_link 'Edit'
        expect(page).to have_link 'Delete'
        expect(page).to have_selector 'button', text: 'Add to collection', count: 1

        # Displays FileSets already attached to this work
        within '.related-files' do
          expect(page).to have_selector '.attribute-filename', text: 'A Contained FileSet'
        end

        # IIIF manifest does not include locale query param
        expect(find('div.viewer-wrapper iframe')['src']).to eq(
          "#{app_host}/uv/uv.html#?manifest=" \
          "#{app_host}/concern/generic_works/#{work.id}/manifest&" \
          "config=#{app_host}/uv/uv-config.json"
        )
      end

      it "allows adding work to a collection",
        clean_repo: true,
        js: true,
        skip: Hyrax.config.use_valkyrie? && 'this failure is unrelated to embargoes (#5844). waiting for valkyrie spec suite improvements' do
          click_button "Add to collection" # opens the modal
          # Really ensure that this Collection model is persisted
          Collection.all.map(&:destroy!)
          persisted_collection = FactoryBot.create(:collection_lw, user: user, collection_type: multi_membership_type_1)
          select_member_of_collection(persisted_collection)
          click_button 'Save changes'

          # forwards to collection show page
          expect(page).to have_content persisted_collection.title.first
          expect(page).to have_content work.title.first
          expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'
        end
    end

    context "as the work viewer" do
      let(:work) do
        create(:public_work,
               with_admin_set: true,
               title: ["Magnificent splendor", "Happy little trees"],
               source: ["The Internet"],
               based_near: ["USA"],
               user: user,
               ordered_members: [file_set],
               representative_id: file_set.id)
      end
      let(:user) { create(:user) }
      let(:viewer) { create(:user) }
      let(:file_set) { create(:file_set, user: user, title: ['A Contained FileSet'], content: file) }
      let(:file) { File.open(fixture_path + '/world.png') }
      let(:multi_membership_type_1) { create(:collection_type, :allow_multiple_membership, title: 'Multi-membership 1') }
      let!(:collection) { FactoryBot.create(:collection_lw, user: viewer, collection_type: multi_membership_type_1) }

      around do |example|
        Hyrax.config.analytics_reporting = true
        example.run
        Hyrax.config.analytics_reporting = false
      end

      before do
        sign_in viewer
        visit work_path
      end

      it "shows work content and only Analytics and Add to collection buttons" do
        expect(page).to have_selector 'h1', text: 'Magnificent splendor'
        expect(page).to have_selector 'h1', text: 'Happy little trees'
        expect(page).to have_selector 'li', text: 'The Internet'
        expect(page).to have_selector 'dt', text: 'Location'
        expect(page).not_to have_selector 'dt', text: 'Based near'
        expect(page).not_to have_selector 'button', text: 'Attach Child', count: 1
        expect(page).to have_link 'Analytics'
        expect(page).not_to have_link 'Edit'
        expect(page).not_to have_link 'Delete'
        expect(page).to have_selector 'button', text: 'Add to collection', count: 1
      end

      it "allows adding work to a collection", clean_repo: true, js: true do
        click_button "Add to collection" # opens the modal
        select_member_of_collection(collection)
        click_button 'Save changes'

        # forwards to collection show page
        sleep 5
        expect(page).to have_content collection.title.first
        expect(page).to have_content work.title.first
        expect(page).to have_selector '.alert-success', text: 'Collection was successfully updated.'

        visit work_path
        expect(page).to have_selector 'a', text: collection.title.first, count: 1
      end
    end

    context "as a user who is not logged in" do
      let(:work) { create(:public_generic_work, title: ["Magnificent splendor"], source: ["The Internet"], based_near: ["USA"]) }
      let(:page_title) { { text: "Generic Work | Magnificent splendor | ID: #{work.id} | Hyrax" }.to_param }

      before do
        visit work_path
      end

      it "shows a work" do
        expect(page).to have_selector 'h1', text: 'Magnificent splendor'
        expect(page).to have_selector 'li', text: 'The Internet'
        expect(page).to have_selector 'dt', text: 'Location'
        expect(page).not_to have_selector 'dt', text: 'Based near'

        # Doesn't have the upload form for uploading more files
        expect(page).not_to have_selector "form#fileupload"

        # has some social media buttons
        expect(page).to have_link '', href: "https://twitter.com/intent/tweet/?#{page_title}&url=#{CGI.escape(app_host)}%2Fconcern%2Fgeneric_works%2F#{work.id}"

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

  context "in valkyrie" do
    let(:work) do
      FactoryBot.valkyrie_create(
        :comet_in_moominland,
        :public,
        abstract: "some fairy creatures meet a child from Sweden I think",
        access_right: "open",
        alternative_title: "mooninland",
        contributor: "Mystery",
        identifier: "867-5309",
        publisher: "Books Incorporated",
        language: "English",
        license: "public domain",
        rights_notes: "no rights reserved",
        source: "springwater"
      )
    end

    before do
      visit work_path
    end

    it "shows a work" do
      expect(page).to have_selector 'h1', text: 'Comet in Moominland'
      expect(page).to have_selector 'dt', text: 'Abstract'
      expect(page).to have_selector 'dt', text: 'Access right'
      expect(page).to have_selector 'dt', text: 'Alternative title'
      expect(page).to have_selector 'dt', text: 'Contributor'
      expect(page).to have_selector 'dt', text: 'Identifier'
      expect(page).to have_selector 'dt', text: 'Publisher'
      expect(page).to have_selector 'dt', text: 'Language'
      expect(page).to have_selector 'dt', text: 'License'
      expect(page).to have_selector 'dt', text: 'Rights notes'
      expect(page).to have_selector 'dt', text: 'Source'

      # Doesn't have the upload form for uploading more files
      expect(page).not_to have_selector "form#fileupload"

      # exports EndNote
      expect(page).to have_link 'EndNote'
      click_link 'EndNote'
      expect(page).to have_content '%0 Monograph'
      expect(page).to have_content '%T Comet in Moominland'
      expect(page).to have_content '%R http://localhost/files/'
      expect(page).to have_content "%~ #{I18n.t('hyrax.product_name')}"
      expect(page).to have_content '%W Institution'
    end
  end
end
