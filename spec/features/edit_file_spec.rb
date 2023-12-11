# frozen_string_literal: true
RSpec.describe "Editing a file:", type: :feature do
  let(:user) { create(:user) }
  let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
  let!(:workflow) { create(:workflow, allows_access_grant: true, active: true, permission_template_id: permission_template.id) }

  let(:admin_set) do
    if Hyrax.config.disable_wings
      valkyrie_create(:hyrax_admin_set)
    else
      create(:admin_set)
    end
  end

  let!(:work) do
    if Hyrax.config.disable_wings
      valkyrie_create(:monograph, depositor: user.user_key, admin_set_id: admin_set.id, members: [file_set])
    else
      build(:work, user: user, admin_set_id: admin_set.id)
    end
  end

  let(:file_set) do
    if Hyrax.config.disable_wings
      valkyrie_create(:hyrax_file_set, :with_files, title: ['Test File Set'], depositor: user.user_key, read_groups: ['public'], edit_users: [user])
    else
      create(:file_set, title: ['Test File Set'], user: user, read_groups: ['public'], edit_users: [user])
    end
  end

  let(:file) { File.open(fixture_path + '/world.png') }

  before do
    sign_in user

    unless Hyrax.config.disable_wings
      Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
      work.ordered_members << file_set
      work.save!
    end
  end

  context 'when the user tries to update file content, but forgets to select a file:' do
    it 'shows the edit page again' do
      visit edit_hyrax_file_set_path(file_set)
      click_link 'Versions'
      click_button 'Upload New Version'
      expect(page).to have_content 'There was a problem processing your request.'
      expect(page).to have_content "Edit #{file_set}"
    end
  end

  context 'when the user tries to update permissions' do
    it 'successfully update visibility' do
      visit edit_hyrax_file_set_path(file_set)
      click_link 'Permissions'

      expect(find('#file_set_visibility_open').checked?).to be(true)

      find('#file_set_visibility_authenticated').click
      find_button('update_permission').click
      expect(page).to have_css('span.badge.badge-info', text: 'Institution')
    end
  end
end
