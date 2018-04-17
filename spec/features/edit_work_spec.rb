RSpec.describe 'Editing a work', type: :feature do
  let(:user) { create(:user) }
  let(:work) { build(:work, user: user, admin_set: another_admin_set) }
  let(:single_membership_type_1) { create(:collection_type, :not_allow_multiple_membership, title: 'Single-membership 1') }
  let(:default_admin_set) do
    create(:admin_set, id: AdminSet::DEFAULT_ID,
                       title: ["Default Admin Set"],
                       description: ["A description"],
                       edit_users: [user.user_key])
  end
  let(:another_admin_set) do
    create(:admin_set, title: ["Another Admin Set"],
                       description: ["A description"],
                       edit_users: [user.user_key])
  end

  before do
    sign_in user
    work.ordered_members << create(:file_set, user: user, title: ['ABC123xyz'])
    work.read_groups = []
    work.save!
  end

  context 'when the user changes permissions' do
    let(:work) { create(:private_work, user: user, admin_set: default_admin_set) }

    it 'confirms copying permissions to files using Hyrax layout and shows updated value', with_nested_reindexing: true do
      # e.g. /concern/generic_works/jq085k20z/edit
      skip
      visit edit_hyrax_generic_work_path(work)
      choose('generic_work_visibility_open')
      check('agreement')
      click_on('Save')
      expect(page).to have_content 'Apply changes to contents?'
      expect(page).not_to have_content "Powered by Hyrax"
      click_on("No. I'll update it manually.")
      within(".panel-heading") do
        expect(page).to have_content('Public')
      end
    end
  end

  context 'when the user two single collectoins', js: true do
    before do
      create(:permission_template_access,
             :deposit,
             permission_template: create(:permission_template, source_id: default_admin_set.id, with_admin_set: true, with_active_workflow: true),
             agent_type: 'user',
             agent_id: user.user_key)
      create(:permission_template_access,
             :deposit,
             permission_template: create(:permission_template, source_id: another_admin_set.id, with_admin_set: true, with_active_workflow: true),
             agent_type: 'user',
             agent_id: user.user_key)
    end
    let(:work) { create(:private_work, user: user, admin_set: default_admin_set) }

    let!(:new_collection) { create(:collection_lw, user: user, collection_type_gid: single_membership_type_1.gid) }
    let!(:single_collection) { create(:collection_lw, user: user, collection_type_gid: single_membership_type_1.gid) }

    # def fill_autocomplete(field, options = {})
    #  fill_in field, :with => options[:with]

    #  page.execute_script %Q{ $('##{field}').#trigger("focus") }
    #  page.execute_script %Q{ $('##{field}').trigger("keydown") }
    #  selector = "input.data-autocomplete a:contains('#{options[:select]}')"

    # page.should have_selector selector
    #  page.execute_script "$(\"#{selector}\").mouseenter().click()"
    # end

    it 'errors out when trying to assign to two collections that are configured to accept only single works', with_nested_reindexing: true do
      visit edit_hyrax_generic_work_path(work)
      click_link "Relationships"
      # select2-chosen select2-chosen-3

      # fill_in('Add to collection', with: new_collection.title.first)
      # within "div.form-inline:first" do
      #      find('a.btn').click
      # end

      # fill_in('Add to collection', with: single_collection.title.first)
      # within "div.form-inline:first" do
      #      find('a.btn').click
      # end

      byebug
      fill_in('Add to collection', with: new_collection.title)
      # click_link 'Add'
      fill_in('Add to collection', with: single_collection.title)
      # click_link 'Add'

      # fill_in('Add to collection', with: new_collection.title.first)
      # fill_in "to_contact_name", :with => "Jone"
      # choose_autocomplete_result "Bob Jones", "#to_contact_name"
      # fill_autocomplete 'Add to collection', with: new_collection.title.first, select: new_collection.title.first

      # find('#generic_work_member_of_collection_ids').native.send_keys(:return)
      # page.execute_script "$('##{field[:id]}').autocomplete('search')"
      # find('#generic_work_member_of_collection_ids').native.send_keys(:return)
      # first('.btn', text: 'Add').click

      # fill_in('Add to collection', with: single_collection.title)
      # find('#generic_work_member_of_collection_ids').native.send_keys(:return)

      # choose_autocomplete_result new_collection.title.first, 'Add to collection'
      # fill_autocomplete 'Add to collection', with: single_collection.title.first, select: single_collection.title.first
      # first('.btn', text: 'Add').click

      check('agreement')
      click_on('Save changes')
      err_message = "Single collection Error: You have specified more than one of the same single-membership collection types: " \
                    "Single-membership 1 (Collection 1 for SM1)"
      byebug
      expect(page).to have_selector '.alert', text: err_message
    end
  end

  context 'when form loads' do
    skip
    before do
      create(:permission_template_access,
             :deposit,
             permission_template: create(:permission_template, source_id: default_admin_set.id, with_admin_set: true, with_active_workflow: true),
             agent_type: 'user',
             agent_id: user.user_key)
      create(:permission_template_access,
             :deposit,
             permission_template: create(:permission_template, source_id: another_admin_set.id, with_admin_set: true, with_active_workflow: true),
             agent_type: 'user',
             agent_id: user.user_key)
    end

    it 'selects admin set already assigned' do
      skip
      visit edit_hyrax_generic_work_path(work)
      click_link "Relationships" # switch tab
      byebug
      expect(page).to have_select('generic_work_admin_set_id', selected: another_admin_set.title)
    end
  end
end
