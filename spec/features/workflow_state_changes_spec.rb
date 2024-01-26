# frozen_string_literal: true
RSpec.describe "Workflow state changes", type: :feature do
  let(:wings_disabled) { Hyrax.config.disable_wings }
  let(:workflow_name) { 'with_comment' }
  let(:approving_user) { create(:admin) }
  let(:depositing_user) { create(:admin) }
  let(:admin_set) do
    if wings_disabled
      valkyrie_create(:hyrax_admin_set, edit_users: [depositing_user])
    else
      create(:admin_set, edit_users: [depositing_user.user_key])
    end
  end
  let(:one_step_workflow) do
    {
      workflows: [
        {
          name: workflow_name,
          label: "One-step mediated deposit workflow",
          description: "A single-step workflow for mediated deposit",
          actions: [
            {
              name: "deposit", from_states: [], transition_to: "pending_review"
            }, {
              name: "approve", from_states: [{ names: ["pending_review"], roles: ["approving"] }],
              transition_to: "deposited",
              methods: ["Hyrax::Workflow::ActivateObject"]
            }, {
              name: "leave_a_comment", from_states: [{ names: ["pending_review"], roles: ["approving"] }]
            }
          ]
        }
      ]
    }
  end

  let(:workflow) { Sipity::Workflow.find_by!(name: workflow_name, permission_template: permission_template) }
  let(:work) do
    if wings_disabled
      valkyrie_create(:monograph, depositor: depositing_user.user_key, admin_set_id: admin_set.id)
    else
      create(:work, user: depositing_user, admin_set: admin_set)
    end
  end
  let(:permission_template) { create(:permission_template, source_id: admin_set.id) }

  before do
    Hyrax::Workflow::WorkflowImporter.generate_from_hash(data: one_step_workflow, permission_template: permission_template)
    permission_template.available_workflows.first.update!(active: true)
    Hyrax::Workflow::PermissionGenerator.call(roles: 'approving', workflow: workflow, agents: approving_user)
    # Need to instantiate the Sipity::Entity for the given work. This is necessary as I'm not creating the work via the UI.
    Hyrax::Workflow::WorkflowFactory.create(work, {}, depositing_user)
  end

  describe 'leaving a comment for non-state changing' do
    it 'will not advance the state' do
      login_as(approving_user, scope: :user)
      wings_disabled ? visit(hyrax_monograph_path(work)) : visit(hyrax_generic_work_path(work))

      expect do
        the_comment = 'I am leaving a great comment. A bigly comment. The best comment.'
        page.choose('workflow_action[name]', option: 'leave_a_comment')

        page.within('.workflow-comments') do
          page.fill_in('workflow_action_comment', with: the_comment)
          page.click_on('Submit')
        end
        expect(page).to have_content(the_comment)
      end.not_to change { Sipity::Entity(work).reload.workflow_state_name }
    end
  end
end
