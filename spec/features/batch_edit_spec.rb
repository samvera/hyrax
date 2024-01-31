# frozen_string_literal: true

RSpec.describe 'batch', type: :feature, clean_repo: true, js: true do
  let(:wings_disabled) { Hyrax.config.disable_wings }
  let(:query_service) { Hyrax.query_service }
  let(:expected_element_text) { wings_disabled ? 'monograph' : 'generic_work' }

  let(:current_user) { create(:user) }
  let(:admin_set) { wings_disabled ? valkyrie_create(:hyrax_admin_set) : create(:admin_set) }
  let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
  let!(:workflow) { create(:workflow, allows_access_grant: true, active: true, permission_template_id: permission_template.id) }
  let!(:work1) do
    if wings_disabled
      valkyrie_create(:monograph,
                      :public,
                      creator: ["Creator"],
                      admin_set_id: admin_set.id,
                      depositor: current_user.user_key,
                      edit_users: [current_user],
                      members: [file_set])
    else
      create(:public_work, creator: ["Creator"], admin_set_id: admin_set.id, user: current_user, ordered_members: [file_set])
    end
  end
  let!(:work2) do
    if wings_disabled
      valkyrie_create(:monograph,
                      :public,
                      creator: ["Creator"],
                      admin_set_id:
                      admin_set.id,
                      depositor: current_user.user_key,
                      edit_users: [current_user])
    else
      create(:public_work, creator: ["Creator"], admin_set_id: admin_set.id, user: current_user)
    end
  end
  let!(:file_set) { wings_disabled ? valkyrie_create(:hyrax_file_set) : create(:file_set) }

  let(:count_of_work_objects) { wings_disabled ? Hyrax.query_service.count_all_of_model(model: Monograph) : GenericWork.count }

  before do
    ::User.group_service.add(user: current_user, groups: ['donor'])
    sign_in current_user
    visit '/dashboard/my/works'
    check 'check_all'
  end

  describe 'editing' do
    it 'changes the value of each field for all selected works' do
      click_on 'batch-edit'
      fill_in_batch_edit_fields_and_verify!
      reloaded_work1 = wings_disabled ? Hyrax.query_service.find_by(id: work1.id) : work1.reload
      reloaded_work2 = wings_disabled ? Hyrax.query_service.find_by(id: work2.id) : work2.reload
      batch_edit_fields.each do |field|
        expect(reloaded_work1.send(field)).to match_array("NEW #{field}")
        expect(reloaded_work2.send(field)).to match_array("NEW #{field}")
      end

      # Reload the form and verify
      visit '/dashboard/my/works'
      check 'check_all'
      find('#batch-edit').click
      expect(page).to have_content('Batch Edit Descriptions')
      batch_edit_expand("creator") do
        page.find("input##{expected_element_text}_creator[value='NEW creator']")
      end
      batch_edit_expand("contributor") do
        page.find("input##{expected_element_text}_contributor[value='NEW contributor']", visible: false)
      end
      batch_edit_expand("description") do
        page.find("textarea##{expected_element_text}_description", text: 'NEW description', visible: false)
      end
      batch_edit_expand("keyword") do
        page.find("input##{expected_element_text}_keyword[value='NEW keyword']", visible: false)
      end
      batch_edit_expand("publisher") do
        page.find("input##{expected_element_text}_publisher[value='NEW publisher']", visible: false)
      end
      batch_edit_expand("date_created") do
        page.find("input##{expected_element_text}_date_created[value='NEW date_created']", visible: false)
      end
      batch_edit_expand("subject") do
        page.find("input##{expected_element_text}_subject[value='NEW subject']", visible: false)
      end
      batch_edit_expand("language") do
        page.find("input##{expected_element_text}_language[value='NEW language']", visible: false)
      end
      batch_edit_expand("identifier") do
        page.find("input##{expected_element_text}_identifier[value='NEW identifier']", visible: false)
      end
      # batch_edit_expand("based_near")
      # expect(page).to have_css "input#generic_work_based_near[value*='NEW based_near']"
      batch_edit_expand("related_url") do
        page.find("input##{expected_element_text}_related_url[value='NEW related_url']", visible: false)
      end
    end

    it 'updates visibility' do
      click_on 'batch-edit'
      find('#edit_permissions_link').click
      batch_edit_expand('permissions_visibility')
      find("##{expected_element_text}_visibility_authenticated").click
      find('#permissions_visibility_save').click

      expect(page).to have_selector('.status', text: 'Changes Saved', visible: true, wait: 30)

      # Verify work is updated
      visit "/concern/#{expected_element_text}s/#{work1.id}/edit#share"
      page.find("##{expected_element_text}_visibility_authenticated:checked")

      # Verify fileset is updated
      visit "concern/file_sets/#{file_set.id}/edit#permissions_display"
      page.find('#file_set_visibility_authenticated:checked')
    end

    it 'updates sharing' do
      click_on 'batch-edit'
      find('#edit_permissions_link').click
      batch_edit_expand('permissions_sharing')
      page.select('donor', from: 'new_group_name_skel')
      page.select('View/Download', from: 'new_group_permission_skel')
      page.find('#add_new_group_skel').click
      find('#collapse_permissions_sharing table', text: 'View/Download')
      find('#collapse_permissions_sharing table', text: 'donor')
      find('#permissions_sharing_save').click

      expect(page).to have_selector('.status', text: 'Changes Saved', visible: true, wait: 30)

      # Verify work is updated
      visit "/concern/#{expected_element_text}s/#{work1.id}/edit#share"
      page.find('#share table', text: 'donor')

      # Verify fileset is updated
      visit "concern/file_sets/#{file_set.id}/edit#permissions_display"
      page.find('#permissions_display table', text: 'donor')
    end
  end

  describe 'deleting' do
    it 'destroys the selected works' do
      accept_confirm { click_button 'Delete Selected' }
      expect(page).to have_content('Batch delete complete')
      expect(count_of_work_objects).to be_zero
    end
  end
end
