RSpec.describe Hyrax::IndexWorkflow do
  subject(:solr_document) { service.to_solr }

  let(:user) { create(:user) }
  let(:service) { described_class.new(resource: work) }
  let(:work) { create_for_repository(:work) }

  context "the object status" do
    before { allow(work).to receive(:suppressed?).and_return(suppressed) }
    context "when suppressed" do
      let(:suppressed) { true }

      it "indexes the suppressed field with a true value" do
        expect(solr_document.fetch('suppressed_bsi')).to be true
      end
    end

    context "when not suppressed" do
      let(:suppressed) { false }

      it "indexes the suppressed field with a false value" do
        expect(solr_document.fetch('suppressed_bsi')).to be false
      end
    end
  end

  context "the actionable workflow roles" do
    let!(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    before do
      allow(Hyrax::Workflow::PermissionQuery).to receive(:scope_roles_associated_with_the_given_entity)
        .and_return(['approve', 'reject'])
    end
    it "indexed the roles and state" do
      expect(solr_document.fetch('actionable_workflow_roles_ssim')).to eq [
        "#{sipity_entity.workflow.permission_template.admin_set_id}-#{sipity_entity.workflow.name}-approve",
        "#{sipity_entity.workflow.permission_template.admin_set_id}-#{sipity_entity.workflow.name}-reject"
      ]
      expect(solr_document.fetch('workflow_state_name_ssim')).to eq "initial"
    end
  end
end
