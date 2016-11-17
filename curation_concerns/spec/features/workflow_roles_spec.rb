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
                "CurationConcerns::Workflow::ActivateObject"
              ]
            }
          ]
        }
      ]
    }
  end
  before do
    allow_any_instance_of(CurationConcerns::Admin::WorkflowRolesController).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
    CurationConcerns::Workflow::WorkflowImporter.new(data: one_step_workflow.as_json).call
    CurationConcerns::Workflow::PermissionGenerator.call(roles: Sipity::Role.all,
                                                         workflow: Sipity::Workflow.last,
                                                         agents: user)
  end

  it "shows the roles" do
    visit '/admin/workflow_roles'
    expect(page).to have_content 'one_step - approving'
  end
end
