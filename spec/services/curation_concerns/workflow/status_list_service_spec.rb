require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::StatusListService do
  describe "#each" do
    let(:user) { create(:user) }
    let(:service) { described_class.new(user) }
    let(:document) { { id: '33333',
                       has_model_ssim: ['GenericWork'],
                       actionable_workflow_roles_ssim: ["generic_work-approving", "generic_work-rejecting"],
                       workflow_state_name_ssim: ["initial"],
                       title_tesim: ['Hey dood!'] } }
    # let(:work) { create(:work, title: ['Hey dood!']) }
    # let(:entity) { create(:sipity_entity,
    #                       proxy_for_global_id: work.to_global_id.to_s) }
    let(:workflow_role) { instance_double(Sipity::Role, name: 'approving') }
    let(:workflow_roles) { [instance_double(Sipity::WorkflowRole, role: workflow_role)] }
    before do
      create(:sipity_entity)
      ActiveFedora::SolrService.add(document, commit: true)
      allow(CurationConcerns::Workflow::PermissionQuery).to receive(:scope_processing_workflow_roles_for_user_and_workflow).and_return(workflow_roles)
    end

    let(:results) { service.each.to_a }

    it "returns status rows" do
      expect(results).not_to be_empty
      expect(results.first).to be_kind_of(SolrDocument)
      expect(results.first.to_s).to eq 'Hey dood!'
      expect(results.first.workflow_state).to eq 'initial'
    end
  end
end
