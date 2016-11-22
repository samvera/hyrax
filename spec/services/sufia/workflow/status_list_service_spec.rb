require 'spec_helper'

RSpec.describe Sufia::Workflow::StatusListService do
  describe "#each" do
    let(:user) { create(:user) }
    let(:service) { described_class.new(user) }
    let(:document) do
      { id: '33333',
        has_model_ssim: ['GenericWork'],
        actionable_workflow_roles_ssim: ["generic_work-approving", "generic_work-rejecting"],
        workflow_state_name_ssim: ["initial"],
        title_tesim: ['Hey dood!'] }
    end
    let(:ability) do
      { id: '44444',
        has_model_ssim: ['GenericWork'],
        title_tesim: ['bad result'] }
    end
    let(:workflow_role) { instance_double(Sipity::Role, name: 'approving') }
    let(:workflow_roles) { [instance_double(Sipity::WorkflowRole, role: workflow_role)] }
    before do
      create(:sipity_entity)
      ActiveFedora::SolrService.add([document, ability], commit: true)
    end

    let(:results) { service.each.to_a }

    context "when user has roles" do
      before do
        allow(Sufia::Workflow::PermissionQuery).to receive(:scope_processing_workflow_roles_for_user_and_workflow).and_return(workflow_roles)
      end

      it "returns status rows" do
        expect(results.size).to eq 1
        expect(results.first).to be_kind_of(SolrDocument)
        expect(results.first.to_s).to eq 'Hey dood!'
        expect(results.first.workflow_state).to eq 'initial'
      end
    end

    context "when user doesn't have roles" do
      before do
        allow(Sufia::Workflow::PermissionQuery).to receive(:scope_processing_workflow_roles_for_user_and_workflow).and_return([])
      end
      it "returns nothing" do
        expect(results).to be_empty
      end
    end
  end
end
