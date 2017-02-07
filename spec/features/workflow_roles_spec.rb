require 'spec_helper'

RSpec.describe "Manage workflow roles", type: :feature do
  let(:user) { create(:admin) }
  let(:one_step_workflow) do
    {
      workflows: [
        {
          name: "one_step",
          label: "One-step mediated deposit workflow",
          description: "A single-step workflow for mediated deposit",
          actions: [
            {
              name: "deposit",
              from_states: [],
              transition_to: "pending_review"
            },
            {
              name: "approve",
              from_states: [
                {
                  names: ["pending_review"],
                  roles: ["approving"]
                }
              ],
              transition_to: "deposited",
              methods: [
                "Hyrax::Workflow::ActivateObject"
              ]
            }
          ]
        }
      ]
    }
  end
  let(:permission_template) { create(:permission_template) }
  before do
    Hyrax::Workflow::WorkflowImporter.generate_from_hash(data: one_step_workflow.as_json, permission_template: permission_template)
    Hyrax::Workflow::PermissionGenerator.call(roles: Sipity::Role.all, workflow: Sipity::Workflow.last, agents: user)
  end

  it "shows the roles" do
    login_as(user, scope: :user)
    visit '/admin/workflow_roles'
    expect(page).to have_content 'one_step - approving'
  end
end
