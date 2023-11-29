# frozen_string_literal: true
RSpec.describe 'Editing a work', :clean_repo, type: :feature do
  let(:user) { create(:user, groups: 'librarians') }
  let(:user_admin) { create(:user, groups: 'admin') }
  let(:work) { valkyrie_create(:monograph, :with_one_file_set, depositor: user.user_key, admin_set_id: another_admin_set.id, edit_users: [user.user_key]) }
  let!(:default_admin_set) do
    valkyrie_create(:hyrax_admin_set,
                    title: Hyrax::AdminSetCreateService::DEFAULT_TITLE,
                    edit_users: [user.user_key],
                    with_permission_template: true,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user.user_key,
                                      access: Hyrax::PermissionTemplateAccess::DEPOSIT }])
  end
  let(:another_admin_set) do
    valkyrie_create(:hyrax_admin_set,
                    edit_users: [user.user_key],
                    with_permission_template: true,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user.user_key,
                                      access: Hyrax::PermissionTemplateAccess::DEPOSIT }])
  end

  before do
    sign_in user
    Hyrax::DefaultAdministrativeSet.update(default_admin_set_id: default_admin_set.id)
  end

  context 'when the user changes permissions' do
    let(:work) { valkyrie_create(:monograph, title: ['Haiku'], depositor: user.user_key, admin_set_id: default_admin_set.id, edit_users: [user.user_key]) }

    it 'confirms copying permissions to files using Hyrax layout and shows updated value' do
      # e.g. /concern/generic_works/jq085k20z/edit
      visit edit_hyrax_monograph_path(work)
      choose('monograph_visibility_open')
      check('agreement')
      click_on('Save')
      within(".work-title-wrapper") do
        expect(page).to have_content('Public')
      end
    end
  end

  context 'when form loads' do
    it 'selects admin set already assigned' do
      visit edit_hyrax_monograph_path(work)
      click_link "Relationships" # switch tab
      expect(page).to have_select('monograph_admin_set_id', selected: another_admin_set.title)
    end

    it 'selects group assigned to user' do
      visit edit_hyrax_monograph_path(work)
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

      visit edit_hyrax_monograph_path(work)
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
