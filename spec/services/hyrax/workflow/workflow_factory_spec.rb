require 'rails_helper'

RSpec.describe Hyrax::Workflow::WorkflowFactory do
  describe '.create' do
    let(:work) { create(:work, with_admin_set: { with_permission_template: true }) }
    let(:permission_template) { Hyrax::PermissionTemplate.find_by!(source_id: work.admin_set_id) }
    let(:workflow) { create(:workflow, active: true, permission_template: permission_template) }
    let(:attributes) { {} }
    let(:user) { create(:user) }
    let(:deposit_action) { Sipity::WorkflowAction.create!(workflow: workflow, name: 'start') }

    subject { described_class.create(work, attributes, user) }

    it 'creates a Sipity::Entity, assign entity specific responsibility (but not to the full workflow) then runs the WorkflowActionService' do
      expect(Hyrax::Workflow::WorkflowActionService).to receive(:run).with(
        subject: kind_of(Hyrax::WorkflowActionInfo), action: deposit_action
      )
      expect do
        expect do
          subject
        end.to change { Sipity::Entity.count }.by(1)
          .and change { Sipity::EntitySpecificResponsibility.count }.by(1)
      end.not_to change { Sipity::WorkflowResponsibility.count }
    end

    it 'skips creating a Sipity::Entity if one already exists' do
      # Yes, this is cheating by setting the workflow_id instead of a valid previously created workflow.
      # However, for this moment, we don't care about the whole AdminSet/PermissionTemplate/Workflow ecosystem.
      Sipity::Entity.create!(proxy_for_global_id: work.to_global_id.to_s, workflow_id: 1)
      expect do
        expect do
          subject
        end.not_to change { Sipity::Entity.count }
      end.not_to change { Sipity::EntitySpecificResponsibility.count }
    end
  end
end
