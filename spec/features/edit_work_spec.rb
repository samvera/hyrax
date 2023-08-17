# frozen_string_literal: true
RSpec.describe 'Editing a work', type: :feature do
  let(:user) { FactoryBot.create(:user, groups: 'librarians') }
  let(:user_admin) { FactoryBot.create(:user, groups: 'admin') }
  let(:work) { FactoryBot.build(:work, user: user, admin_set: another_admin_set) }
  let(:default_admin_set) do
    FactoryBot.create(:admin_set, id: AdminSet::DEFAULT_ID,
                                  title: ["Default Admin Set"],
                                  description: ["A description"],
                                  edit_users: [user.user_key])
  end
  let(:another_admin_set) do
    FactoryBot.create(:admin_set, title: ["Another Admin Set"],
                                  description: ["A description"],
                                  edit_users: [user.user_key])
  end

  before do
    sign_in user
    work.ordered_members << create(:file_set, user: user, title: ['ABC123xyz'])
    work.read_groups = []
    work.save!

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

  context 'when the user changes permissions' do
    let(:work) { create(:private_work, user: user, admin_set: default_admin_set) }

    it 'confirms copying permissions to files using Hyrax layout and shows updated value' do
      # e.g. /concern/generic_works/jq085k20z/edit
      visit edit_hyrax_generic_work_path(work)
      choose('generic_work_visibility_open')
      check('agreement')
      click_on('Save')
      expect(page).to have_content 'Apply changes to contents?'
      expect(page).not_to have_content "Powered by Hyrax"
      click_on("No. I'll update it manually.")
      within(".work-title-wrapper") do
        expect(page).to have_content('Public')
      end
    end
  end

  context 'when form loads' do
    it 'selects admin set already assigned' do
      visit edit_hyrax_generic_work_path(work)
      click_link "Relationships" # switch tab
      expect(page).to have_select('generic_work_admin_set_id', selected: another_admin_set.title)
    end

    it 'selects group assigned to user' do
      visit edit_hyrax_generic_work_path(work)
      click_link "Sharing" # switch tab
      expect(page).to have_selector('#new_group_name_skel', text: 'librarians')
    end
  end

  context 'when logged in as admin' do
    before do
      sign_in user_admin
    end

    it 'selects group all available groups' do
      FactoryBot.create(:user, groups: 'donor')

      visit edit_hyrax_generic_work_path(work)
      click_link "Sharing" # switch tab
      expect(page).to have_selector('#new_group_name_skel', text: 'librarians admin donor')
    end
  end

  context 'with a parent Valkyrie resource', valkyrie_adapter: :test_adapter, index_adapter: :solr_index do
    let(:monograph) { FactoryBot.valkyrie_create(:monograph, :with_member_works) }

    before do
      sign_in user_admin
    end

    it 'displays an edit page with a relationships tab' do
      visit edit_hyrax_monograph_path(monograph)
      expect(page).to have_link("Relationships")
    end
  end
end
