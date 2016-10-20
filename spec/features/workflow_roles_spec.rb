require 'spec_helper'

RSpec.describe "Manage workflow roles", type: :feature do
  let(:user) { create(:user) }
  before do
    allow_any_instance_of(CurationConcerns::Admin::WorkflowRolesController).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
    CurationConcerns::Workflow::WorkflowImporter.generate_from_json_file(path: "#{EngineCart.destination}/config/workflows/generic_work_workflow.json")
    CurationConcerns::Workflow::PermissionGenerator.call(roles: Sipity::Role.all,
                                                         workflow: Sipity::Workflow.last,
                                                         agents: user)
  end

  it "shows the roles" do
    visit '/admin/workflow_roles'
    expect(page).to have_content 'generic_work - reviewing'
  end
end
