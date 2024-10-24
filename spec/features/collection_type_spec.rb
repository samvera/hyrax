# frozen_string_literal: true

RSpec.describe 'collection_type', type: :feature do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:exhibit_collection_type) do
    FactoryBot.create(:collection_type,
                      title: 'Exhibit',
                      description: 'Description for exhibit collection type.',
                      creator_user: admin_user)
  end
  let(:user_collection_type) { FactoryBot.create(:user_collection_type) }
  let(:admin_set_type) { FactoryBot.create(:admin_set_collection_type) }
  let(:solr_gid) { Hyrax.config.collection_type_index_field }

  shared_context('sign in as admin and go to collection types index') do
    before do
      sign_in admin_user
      visit '/admin/collection_types'
    end
  end

  describe 'index' do
    before do
      exhibit_collection_type
      user_collection_type
      admin_set_type
    end
    include_context 'sign in as admin and go to collection types index'

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

    include_context 'sign in as admin and go to collection types index'

    it 'makes a new collection type', :js do
      checks_for_standard_form_options
      fill_in_and_save

      # confirm values were set
      expect(page).to have_selector "input#collection_type_title[value='#{title}']"
      expect(page).to have_selector 'textarea#collection_type_description', text: description

      all_edit_tabs_visible
    end

    it 'tries to make a collection type with existing title, and receives error message', :js do
      checks_for_standard_form_options
      fill_in_and_save

      visit '/admin/collection_types'
      click_link 'Create new collection type'

      expect(page).to have_content 'Create New Collection Type'

      only_description_tab_and_metadata_fields_visible

      fill_in_and_save

      # Confirm error message is displayed.
      expect(page).to have_content 'Save was not successful because title has already been taken, and machine_id has already been taken.'
    end
  end

  describe 'edit collection type' do
    context 'when there are no collections of this type', :clean_repo do
      before do
        exhibit_collection_type
        sign_in admin_user
        visit "/admin/collection_types/#{exhibit_collection_type.id}/edit"
      end

      it 'modifies metadata values of a collection type', :js do
        expect(page).to have_content "Edit Collection Type: Exhibit"

        all_edit_tabs_visible

        # confirm metadata fields have original values
        expect(page).to have_selector "input#collection_type_title[value='Exhibit']"
        expect(page).to have_selector 'textarea#collection_type_description', text: 'Description for exhibit collection type.'

        # set values and save
        fill_in('Type name', with: 'Exhibit modified')
        fill_in('Type description', with: 'Change in description for exhibit collection type.')

        click_button('Save changes')

        expect(page).to have_content "Edit Collection Type: Exhibit modified"

        # confirm values were set
        expect(page).to have_selector "input#collection_type_title[value='Exhibit modified']"
        expect(page).to have_selector 'textarea#collection_type_description', text: 'Change in description for exhibit collection type.'

        click_link('Settings', href: '#settings')

        # confirm all non-admin_set checkboxes are on
        expect(page).to have_checked_field('collection_type_nestable')
        expect(page).to have_checked_field('collection_type_brandable')
        expect(page).to have_checked_field('collection_type_discoverable')
        expect(page).to have_checked_field('collection_type_sharable')
        expect(page).to have_checked_field('collection_type_share_applies_to_new_works')
        expect(page).to have_checked_field('collection_type_allow_multiple_membership')

        all_admin_set_checkboxes_off_and_disabled

        # change settings
        page.uncheck('NESTING')
        page.uncheck('DISCOVERY')
        page.check('APPLY TO NEW WORKS')
        page.uncheck('MULTIPLE MEMBERSHIP')

        # confirm all non-admin_set checkboxes are now off
        expect(page).to have_unchecked_field('collection_type_nestable')
        expect(page).to have_checked_field('collection_type_brandable')
        expect(page).to have_unchecked_field('collection_type_discoverable')
        expect(page).to have_checked_field('collection_type_sharable')
        expect(page).to have_checked_field('collection_type_share_applies_to_new_works')
        expect(page).to have_unchecked_field('collection_type_allow_multiple_membership')

        # uncheck sharable should disable sharable options
        page.uncheck('SHARING')

        expect(page).to have_unchecked_field('collection_type_sharable')
        expect(page).to have_unchecked_field('collection_type_share_applies_to_new_works', disabled: true)

        # check sharable should enable sharable options
        page.check('SHARING')

        expect(page).to have_checked_field('collection_type_sharable')
        expect(page).to have_unchecked_field('collection_type_share_applies_to_new_works', disabled: false)

        click_link('Participants')

        # TODO: Test adding participants
      end

      context 'when editing default user collection type' do
        let(:title_old) { user_collection_type.title }
        let(:description_old) { user_collection_type.description }
        let(:title_new) { 'User Collection modified' }
        let(:description_new) { 'Change in description for user collection type.' }

        before do
          user_collection_type
          sign_in admin_user
          visit "/admin/collection_types/#{user_collection_type.id}/edit"
        end

        it 'allows editing of metadata, but not settings', :js do
          expect(page).to have_content "Edit Collection Type: #{title_old}"

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

          # confirm default user collection checkboxes are set to appropriate values
          expect(page).to have_checked_field('collection_type_nestable', disabled: true)
          expect(page).to have_checked_field('collection_type_brandable', disabled: true)
          expect(page).to have_checked_field('collection_type_discoverable', disabled: true)
          expect(page).to have_checked_field('collection_type_sharable', disabled: true)
          expect(page).to have_unchecked_field('collection_type_share_applies_to_new_works', disabled: true)
          expect(page).to have_checked_field('collection_type_allow_multiple_membership', disabled: true)

          all_admin_set_checkboxes_off_and_disabled
        end
      end

      context 'when editing admin set collection type' do
        let(:title_old) { admin_set_type.title }
        let(:description_old) { admin_set_type.description }
        let(:description_new) { 'Change in description for admin set collection type.' }

        before do
          admin_set_type
          sign_in admin_user
          visit "/admin/collection_types/#{admin_set_type.id}/edit"
        end

        it 'allows editing of metadata except title, but not settings', :js do
          expect(page).to have_content "Edit Collection Type: #{title_old}"

          # confirm metadata fields have original values
          expect(page).to have_field("collection_type_title", disabled: true)
          expect(page).to have_selector 'textarea#collection_type_description', text: description_old

          # set values and save
          fill_in('Type description', with: description_new)

          click_button('Save changes')

          expect(page).to have_content "Edit Collection Type: #{title_old}"

          # confirm values were set
          expect(page).to have_selector 'textarea#collection_type_description', text: description_new

          click_link('Settings', href: '#settings')

          # confirm default user collection checkboxes are set to appropriate values
          expect(page).to have_unchecked_field('collection_type_nestable', disabled: true)
          expect(page).to have_unchecked_field('collection_type_discoverable', disabled: true)
          expect(page).to have_checked_field('collection_type_sharable', disabled: true)
          expect(page).to have_checked_field('collection_type_share_applies_to_new_works', disabled: true)
          expect(page).to have_unchecked_field('collection_type_allow_multiple_membership', disabled: true)

          # confirm all admin_set only checkboxes are off and disabled
          expect(page).to have_checked_field('collection_type_require_membership', disabled: true)
          expect(page).to have_checked_field('collection_type_assigns_workflow', disabled: true)
          expect(page).to have_checked_field('collection_type_assigns_visibility', disabled: true)
        end
      end
    end

    context 'when collections exist of this type' do
      let!(:collection1) do
        FactoryBot.valkyrie_create(:hyrax_collection, :public, user: create(:user), collection_type_gid: exhibit_collection_type.to_global_id)
      end

      before do
        exhibit_collection_type
        sign_in admin_user
        visit "/admin/collection_types/#{exhibit_collection_type.id}/edit"
      end

      it 'all settings are disabled', :js do
        expect(exhibit_collection_type.collections.any?).to be true

        click_link('Settings', href: '#settings')

        # confirm all checkboxes are disabled
        expect(page).to have_field('collection_type_nestable', disabled: true)
        expect(page).to have_field('collection_type_brandable', disabled: true)
        expect(page).to have_field('collection_type_discoverable', disabled: true)
        expect(page).to have_field('collection_type_sharable', disabled: true)
        expect(page).to have_field('collection_type_share_applies_to_new_works', disabled: true)
        expect(page).to have_field('collection_type_allow_multiple_membership', disabled: true)
        expect(page).to have_field('collection_type_require_membership', disabled: true)
        expect(page).to have_field('collection_type_assigns_workflow', disabled: true)
        expect(page).to have_field('collection_type_assigns_visibility', disabled: true)
      end
    end
  end

  describe 'delete collection type' do
    context 'when there are no collections of this type', :clean_repo do
      let!(:empty_collection_type) { create(:collection_type, title: 'Empty Type', creator_user: admin_user) }
      let!(:delete_modal_text) { 'Deleting this collection type will permanently remove the type and its settings from the repository. Are you sure you want to delete this collection type?' }
      let!(:deleted_flash_text) { "The collection type #{empty_collection_type.title} has been deleted." }

      include_context 'sign in as admin and go to collection types index'

      it 'shows warning, deletes collection type, and shows flash message on success', :js do
        expect(page).to have_content(empty_collection_type.title)

        find(:xpath, "//tr[td[contains(.,'#{empty_collection_type.title}')]]/td/button", text: 'Delete').click

        within('div#deleteModal') do
          expect(page).to have_content(delete_modal_text)
          click_button('Delete')
        end

        within('.alert-success') do
          expect(page).to have_content(deleted_flash_text)
        end

        within('.collection-types-table') do
          expect(page).not_to have_content(empty_collection_type.title)
        end
      end
    end

    shared_examples('tests the inability to delete collection types that are associated to persisted collections') do
      let!(:not_empty_collection_type) { FactoryBot.create(:collection_type, title: 'Not Empty Type', creator_user: admin_user) }
      let!(:collection1) { FactoryBot.valkyrie_create(:hyrax_collection, :public, user: admin_user, collection_type_gid: not_empty_collection_type.to_global_id) }

      let(:deny_delete_modal_text) do
        'You cannot delete this collection type because one or more collections of this type have already been created. ' \
        'To delete this collection type, first ensure that all collections of this type have been deleted.'
      end

      include_context 'sign in as admin and go to collection types index'

      it 'shows unable to delete dialog and forwards to All Collections with filter applied', :js do
        expect(page).to have_content(not_empty_collection_type.title)

        find(:xpath, "//tr[td[contains(.,'#{not_empty_collection_type.title}')]]/td/button", text: 'Delete').click

        within('div#deleteDenyModal') do
          # Check both hidden and visible HTML attributes
          expect(page).to have_content(:all, deny_delete_modal_text)
          click_link('View collections of this type')
        end

        # forwards to Dashboard -> Collections -> All Collections
        within('.nav-tabs li.nav-item') do
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

    context 'when collections exist of this type (ActiveFedora)', :active_fedora do
      include_examples 'tests the inability to delete collection types that are associated to persisted collections'
    end

    context 'when collections exist of this type (Valkyrie)' do
      include_examples 'tests the inability to delete collection types that are associated to persisted collections' if Hyrax.config.disable_wings
    end
  end

  def only_description_tab_and_metadata_fields_visible
    # confirm only Description tab is visible
    expect(page).to have_link('Description', href: '#metadata')
    expect(page).not_to have_link('Settings', href: '#settings')
    expect(page).not_to have_link('Participants', href: '#participants')

    # confirm metadata fields exist
    expect(page).to have_selector 'input#collection_type_title'
    expect(page).to have_selector 'textarea#collection_type_description'
  end

  def all_edit_tabs_visible
    # confirm all edit tabs are now visible
    expect(page).to have_link('Description', href: '#metadata')
    expect(page).to have_link('Settings', href: '#settings')
    expect(page).to have_link('Participants', href: '#participants')
  end

  def checks_for_standard_form_options
    click_link 'Create new collection type'

    expect(page).to have_content 'Create New Collection Type'

    only_description_tab_and_metadata_fields_visible
  end

  def fill_in_and_save
    # set values and save
    fill_in('Type name', with: title)
    fill_in('Type description', with: description)

    click_button('Save')
  end

  def all_admin_set_checkboxes_off_and_disabled
    # confirm all admin_set only checkboxes are off and disabled
    expect(page).to have_unchecked_field('collection_type_require_membership', disabled: true)
    expect(page).to have_unchecked_field('collection_type_assigns_workflow', disabled: true)
    expect(page).to have_unchecked_field('collection_type_assigns_visibility', disabled: true)
  end
end
