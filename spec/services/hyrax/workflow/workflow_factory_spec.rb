# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Workflow::WorkflowFactory do
  subject(:factory) { described_class }

  let(:attributes) { {} }
  let(:deposit_action) { Sipity::WorkflowAction.create!(workflow: workflow, name: 'start') }
  let(:permission_template) { Hyrax::PermissionTemplate.find_by!(source_id: work.admin_set_id) }
  let(:user) { FactoryBot.create(:user) }
  let(:work) { create(:work, with_admin_set: { with_permission_template: true }) }
  let(:workflow) { FactoryBot.create(:workflow, active: true, permission_template: permission_template) }

  describe '.create' do
    it 'creates a Sipity::Entity, assign entity specific responsibility (but not to the full workflow) then runs the WorkflowActionService' do
      expect(Hyrax::Workflow::WorkflowActionService)
        .to receive(:run)
        .with(subject: kind_of(Hyrax::WorkflowActionInfo), action: deposit_action)

      expect do
        expect { factory.create(work, attributes, user) }
          .to change { Sipity::Entity.count }.by(1)
          .and change { Sipity::EntitySpecificResponsibility.count }.by(1)
      end.not_to change { Sipity::WorkflowResponsibility.count }
    end
  end
end
