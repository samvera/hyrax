# frozen_string_literal: true
RSpec.describe Hyrax::Workflow::StatusListService do
  subject(:service) { described_class.new(user, "workflow_state_name_ssim:initial") }
  let(:user) { FactoryBot.create(:user) }

  context 'using valkyrie models',
          index_adapter: :solr_index,
          valkyrie_adapter: :test_adapter do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

    before { Hyrax.index_adapter.save(resource: work) }

    it 'without any roles is empty' do
      expect(service.each).to be_none
    end
  end

  context "#each with ActiveFedora objects", :active_fedora do
    let(:document) do
      { id: '33333',
        has_model_ssim: ['GenericWork'],
        actionable_workflow_roles_ssim: ["foobar-generic_work-approving", "foobar-generic_work-rejecting"],
        workflow_state_name_ssim: ["initial"],
        title_tesim: ['Hey dood!'] }
    end
    let(:bad_document) do
      { id: '44444',
        has_model_ssim: ['GenericWork'],
        title_tesim: ['bad result'] }
    end

    before do
      Hyrax::SolrService.add([document, bad_document], commit: true)
    end

    context "when user has roles" do
      let(:template) { double('template', source_id: 'foobar') }
      let(:workflow_role) { instance_double(Sipity::Role, name: 'approving') }
      let(:workflow_roles) { [instance_double(Sipity::WorkflowRole, role: workflow_role)] }

      let(:workflow) do
        instance_double(Sipity::Workflow, name: 'generic_work', permission_template: template)
      end

      before do
        allow(Hyrax::Workflow::PermissionQuery).to receive(:scope_processing_workflow_roles_for_user_and_workflow).and_return(workflow_roles)
        allow(Sipity::Workflow).to receive(:all).and_return([workflow])
      end

      it "returns status rows" do
        expect(service.each.count).to eq 1
        expect(service.each.first).to be_kind_of(SolrDocument)
        expect(service.each.first.to_s).to eq 'Hey dood!'
        expect(service.each.first.workflow_state).to eq 'initial'
      end
    end

    context "when user doesn't have roles" do
      before do
        allow(Hyrax::Workflow::PermissionQuery).to receive(:scope_processing_workflow_roles_for_user_and_workflow).and_return([])
      end

      it "returns nothing" do
        expect(service.each).to be_none
      end
    end
  end
end
