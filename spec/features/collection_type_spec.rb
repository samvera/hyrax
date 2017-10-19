RSpec.describe 'collection_type', type: :feature, clean_repo: true do
  let(:admin_user) { create(:admin) }
  let(:exhibit_title) { 'Exhibit' }
  let(:exhibit_description) { 'Description for exhibit collection type.' }
  let(:exhibit_collection_type) { create(:collection_type, title: exhibit_title, description: exhibit_description, creator_user: admin_user) }
  let(:user_collection_type) { create(:user_collection_type) }
  let(:admin_set_type) { create(:admin_set_collection_type) }
  let(:solr_gid) { Collection.collection_type_gid_document_field_name }

  describe 'index' do
    before do
      exhibit_collection_type
      user_collection_type
      admin_set_type
      sign_in admin_user
      visit '/admin/collection_types'
    end

    it 'has page title and lists collection types' do
      expect(page).to have_content 'Collection Types'

      expect(page).to have_content 'Admin Set'
      expect(page).to have_content 'User Collection'
      expect(page).to have_content 'Collection Type'

      expect(page).to have_link('Edit', count: 3)
      expect(page).to have_link('Edit', href: hyrax.edit_admin_collection_type_path(admin_set_type.id, locale: 'en'))
      expect(page).to have_link('Edit', href: hyrax.edit_admin_collection_type_path(user_collection_type.id, locale: 'en'))
      expect(page).to have_link('Edit', href: hyrax.edit_admin_collection_type_path(exhibit_collection_type.id, locale: 'en'))
      expect(page).to have_button('Delete', count: 2) # 1: Collection Type, 2: delete modal
    end
  end

  describe 'create collection type' do
    let(:title) { 'Test Type' }
    let(:description) { 'Description for collection type we are testing.' }

    before do
      sign_in admin_user
      visit '/admin/collection_types'
    end

    it 'makes a new collection type', :js do
      click_link 'Create new collection type'

      expect(page).to have_content 'Create New Collection Type'

      # confirm only Description tab is visible
      expect(page).to have_link('Description', href: '#metadata')
      expect(page).not_to have_link('Settings', href: '#settings')
      expect(page).not_to have_link('Participants', href: '#participants')

      # confirm metadata fields exist
      expect(page).to have_selector 'input#collection_type_title'
      expect(page).to have_selector 'textarea#collection_type_description'

      # set values and save
      fill_in('Type name', with: title)
      fill_in('Type description', with: description)

      click_button('Save')

      # confirm values were set
      expect(page).to have_selector "input#collection_type_title[value='#{title}']"
      expect(page).to have_selector 'textarea#collection_type_description', text: description

      # confirm all edit tabs are now visible
      expect(page).to have_link('Description', href: '#metadata')
      expect(page).to have_link('Settings', href: '#settings')
      expect(page).to have_link('Participants', href: '#participants')
    end
  end

  describe 'edit collection type' do
    context 'when there are no collections of this type' do
      let(:title_old) { exhibit_title }
      let(:description_old) { exhibit_description }
      let(:title_new) { 'Exhibit modified' }
      let(:description_new) { 'Change in description for exhibit collection type.' }

      before do
        exhibit_collection_type
        sign_in admin_user
        visit "/admin/collection_types/#{exhibit_collection_type.id}/edit"
      end

      it 'modifies metadata values of a collection type', :js do
        expect(page).to have_content "Edit Collection Type: #{title_old}"

        # confirm all tabs are visible
        expect(page).to have_link('Description', href: '#metadata')
        expect(page).to have_link('Settings', href: '#settings')
        expect(page).to have_link('Participants', href: '#participants')

        # confirm metadata fields have original values
        expect(page).to have_selector "input#collection_type_title[value='#{title_old}']"
        expect(page).to have_selector 'textarea#collection_type_description', text: description_old

        # set values and save
        fill_in('Type name', with: title_new)
        fill_in('Type description', with: description_new)

        click_button('Save changes')

        expect(page).to have_content "Edit Collection Type: #{title_new}"

        # confirm values were set
        expect(page).to have_selector "input#collection_type_title[value='#{title_new}']"
        expect(page).to have_selector 'textarea#collection_type_description', text: description_new

        click_link('Settings', href: '#settings')

        # confirm all non-admin_set checkboxes are on
        expect(page).to have_checked_field('collection_type_nestable')
        expect(page).to have_checked_field('collection_type_discoverable')
        expect(page).to have_checked_field('collection_type_sharable')
        expect(page).to have_checked_field('collection_type_allow_multiple_membership')

        # confirm all admin_set only checkboxes are off and disabled
        expect(page).to have_unchecked_field('collection_type_require_membership', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_workflow', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_visibility', disabled: true)

        # change settings
        page.uncheck('NESTABLE')
        page.uncheck('DISCOVERY')
        page.uncheck('SHARING')
        page.uncheck('MULTIPLE MEMBERSHIP')

        # confirm all non-admin_set checkboxes are now off
        expect(page).to have_unchecked_field('collection_type_nestable')
        expect(page).to have_unchecked_field('collection_type_discoverable')
        expect(page).to have_unchecked_field('collection_type_sharable')
        expect(page).to have_unchecked_field('collection_type_allow_multiple_membership')

        click_link('Participants')

        # TODO: Test adding participants
      end
    end

    context 'when collections exist of this type' do
      let!(:collection1) { create(:public_collection, user: build(:user), collection_type_gid: exhibit_collection_type.gid) }

      before do
        exhibit_collection_type
        sign_in admin_user
        visit "/admin/collection_types/#{exhibit_collection_type.id}/edit"
      end

      it 'all settings are disabled', :js do
        expect(exhibit_collection_type.collections?).to be true

        click_link('Settings', href: '#settings')

        # confirm all checkboxes are disabled
        expect(page).to have_field('collection_type_nestable', disabled: true)
        expect(page).to have_field('collection_type_discoverable', disabled: true)
        expect(page).to have_field('collection_type_sharable', disabled: true)
        expect(page).to have_field('collection_type_allow_multiple_membership', disabled: true)
        expect(page).to have_field('collection_type_require_membership', disabled: true)
        expect(page).to have_field('collection_type_assigns_workflow', disabled: true)
        expect(page).to have_field('collection_type_assigns_visibility', disabled: true)
      end
    end
  end

  describe 'delete collection type' do
    context 'when there are no collections of this type' do
      let!(:empty_collection_type) { create(:collection_type, title: 'Empty Type', creator_user: admin_user) }
      let!(:delete_modal_text) { 'Deleting this collection type will permanently remove the type and its settings from the repository.  Are you sure you want to delete this collection type?' }

      before do
        sign_in admin_user
        visit '/admin/collection_types'
      end

      it 'shows warning and deletes collection type', :js do
        expect(page).to have_content(empty_collection_type.title)

        find(:xpath, "//tr[td[contains(.,'#{empty_collection_type.title}')]]/td/button", text: 'Delete').click

        within('div#deleteModal') do
          expect(page).to have_content(delete_modal_text)
          click_button('Delete')
        end

        expect(page).not_to have_content(empty_collection_type.title)
      end
    end

    context 'when collections exist of this type' do
      let!(:not_empty_collection_type) { create(:collection_type, title: 'Not Empty Type', creator_user: admin_user) }
      let!(:collection1) { create(:public_collection, user: admin_user, collection_type_gid: not_empty_collection_type.gid) }
      let(:deny_delete_modal_text) do
        'You cannot delete this collection type because one or more collections of this type have already been created. ' \
        'To delete this collection type, first ensure that all collections of this type have been deleted.'
      end

      before do
        sign_in admin_user
        visit '/admin/collection_types'
      end

      it 'shows unable to delete dialog and forwards to All Collections with filter applied', :js do
        expect(page).to have_content(not_empty_collection_type.title)

        find(:xpath, "//tr[td[contains(.,'#{not_empty_collection_type.title}')]]/td/button", text: 'Delete').click

        within('div#deleteDenyModal') do
          expect(page).to have_content(deny_delete_modal_text)
          click_link('View collections of this type')
        end

        # forwards to Dashboard -> Collections -> All Collections
        within('li.active') do
          expect(page).to have_link('All Collections')
        end

        # filter is applied
        within('div#appliedParams') do
          expect(page).to have_content('Filtering by:')
          expect(page).to have_content('Type')
          expect(page).to have_content(not_empty_collection_type.title)
        end

        # collection of this type is in the list of collections
        expect(page).to have_content(collection1.title.first)
      end
    end
  end
end
