require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Read Only Mode' do
  let(:admin) { create :user }

  context 'a logged in user' do
    let(:user) do
      User.new(email: 'test@example.com', guest: false, uid: 'test@example.com') { |u| u.save!(validate: false)}
    end

    let(:admin_user) do
      User.find_by_user_key('admin@example.com')
    end

    let(:admin_set) do
      AdminSet.create(title: ["work admin set"],
                      description: ["some description"],
                      edit_users: [user.user_key])
    end

    let(:permission_template) do
      Hyrax::PermissionTemplate.create!(source_id: admin_set.id)
    end

    let(:workflow) { Sipity::Workflow.find_by!(name: 'default', permission_template: permission_template) }

    let(:admin_agent) { Sipity::Agent.where(proxy_for_id: admin_user.id, proxy_for_type: 'User').first_or_create }
    let(:user_agent) { Sipity::Agent.where(proxy_for_id: user.id, proxy_for_type: 'User').first_or_create }

    before do
      Hyrax::PermissionTemplateAccess.create(permission_template: permission_template,
                                             agent_type: 'user',
                                             agent_id: user.user_key,
                                             access: 'deposit')
      Hyrax::PermissionTemplateAccess.create(permission_template: permission_template,
                                             agent_type: 'user',
                                             agent_id: admin_user.user_key,
                                             access: 'deposit')
      Hyrax::Workflow::WorkflowImporter.generate_from_json_file(path: Rails.root.join('config',
                                                                                      'workflows',
                                                                                      'default_workflow.json'),
                                                                permission_template: permission_template)
      Hyrax::Workflow::PermissionGenerator.call(roles: 'approving', workflow: workflow, agents: user_agent)
      Hyrax::Workflow::PermissionGenerator.call(roles: 'depositing', workflow: workflow, agents: user_agent)
      Hyrax::Workflow::PermissionGenerator.call(roles: 'approving', workflow: workflow, agents: admin_agent)
      Hyrax::Workflow::PermissionGenerator.call(roles: 'depositing', workflow: workflow, agents: admin_agent)
      permission_template.available_workflows.first.update!(active: true)
      DefaultAdminSet.create(work_type_name: 'Work', admin_set_id: admin_set.id)
    end

    scenario 'as a non-admin', js: false do
      login_as user

      visit new_hyrax_work_path
      expect(page).to have_content('Add New Work')

      allow(Flipflop).to receive(:read_only?).and_return(true)
      visit new_hyrax_work_path
      expect(page).to have_content('The repository is in read-only mode for maintenance.')

      allow(Flipflop).to receive(:read_only?).and_return(false)
      visit new_hyrax_work_path
      expect(page).to have_content('Add New Undergraduate Honors Thesis')
    end

    scenario 'as admin', js: false do
      login_as admin_user

      visit new_hyrax_work_path
      expect(page).to have_content('Add New Undergraduate Honors Thesis')

      allow(Flipflop).to receive(:read_only?).and_return(true)
      visit new_hyrax_work_path
      expect(page).to have_content('The repository is in read-only mode for maintenance.')

      allow(Flipflop).to receive(:read_only?).and_return(false)
      visit new_hyrax_work_path
      expect(page).to have_content('Add New Work')
    end
  end
end