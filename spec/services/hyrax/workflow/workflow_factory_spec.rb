# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Workflow::WorkflowFactory do
  subject(:factory) { described_class }

  let(:attributes) { {} }
  let(:deposit_action) { Sipity::WorkflowAction.create!(workflow: workflow, name: 'start') }
  let(:permission_template) { Hyrax::PermissionTemplate.find_by!(source_id: work.admin_set_id.to_s) }
  let(:user) { FactoryBot.create(:user) }
  let(:work) { create(:work, with_admin_set: { with_permission_template: true }) }
  let(:workflow) { FactoryBot.create(:workflow, active: true, permission_template: permission_template) }

  shared_examples 'a workflow initializer' do
    it 'creates a Sipity::Entity, assign entity specific responsibility (but not to the full workflow) then runs the WorkflowActionService' do
      expect(Hyrax::Workflow::WorkflowActionService)
        .to receive(:run).with(subject: kind_of(Hyrax::WorkflowActionInfo), action: deposit_action)

      initial_workflow_responsibility_count = Sipity::WorkflowResponsibility.count
      expect { factory.create(work, attributes, user) }
        .to change { Sipity::Entity.count }
        .by(1)
        .and change { Sipity::EntitySpecificResponsibility.count }
        .by(1)
      expect(Sipity::WorkflowResponsibility.count).to eq initial_workflow_responsibility_count
    end
  end

  describe '.create' do
    context 'with an ActiveFedora work', :active_fedora do
      it_behaves_like 'a workflow initializer'

      it 'rejects models without an admin_set_id' do
        resource = FactoryBot.valkyrie_create(:hyrax_resource)

        expect { factory.create(resource, attributes, user) }
          .to raise_error Sipity::StateError
      end
    end

    context 'with a valkyrie work' do
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, with_permission_template: true) }
      let(:work)      { FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id) }

      it_behaves_like 'a workflow initializer'
    end
  end
end
