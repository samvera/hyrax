require 'spec_helper'

RSpec.describe "Manage workflow roles", type: :feature do
  let(:user) { create(:user) }
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
              transition_to: "complete",
              methods: [
                "Sufia::Workflow::ActivateObject"
              ]
            }
          ]
        }
      ]
    }
  end
  before do
    allow(RoleMapper).to receive(:byname).and_return(user.user_key => ['admin'])
    Sufia::Workflow::WorkflowImporter.new(data: one_step_workflow.as_json).call
    Sufia::Workflow::PermissionGenerator.call(roles: Sipity::Role.all,
                                              workflow: Sipity::Workflow.last,
                                              agents: user)
  end

  it "shows the roles" do
    login_as(user, scope: :user)
    visit '/admin/workflow_roles'
    expect(page).to have_content 'one_step - approving'
  end
end
