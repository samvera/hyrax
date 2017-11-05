module Hyrax
  module Workflow
    RSpec.describe PermissionGenerator do
      let(:user) { create(:user) }
      let(:role) { Sipity::Role.create!(name: 'creating_user') }
      let(:workflow) { create(:workflow, name: 'workflow') }
      let(:workflow_state) { workflow.initial_workflow_state }
      let(:entity) do
        Sipity::Entity.create!(proxy_for_global_id: "gid://work/1", workflow: workflow, workflow_state: workflow_state)
      end
      let(:another_entity) do
        Sipity::Entity.create!(proxy_for_global_id: "gid://work/2", workflow: workflow, workflow_state: workflow_state)
      end
      let(:action_name) { 'show' }

      it 'will grant workflow responsible to agent as the given role' do
        expect do
          described_class.call(agents: user, roles: role.name, workflow: workflow)
        end.to change { Sipity::WorkflowRole.count }.by(1)
                                                    .and change { Sipity::WorkflowResponsibility.count }.by(1)
      end

      it 'will grant entity responsiblity to agent as the given role' do
        expect do
          described_class.call(agents: user, roles: role.name, workflow: workflow, entity: entity)
        end.to change { Sipity::WorkflowRole.count }.by(1)
                                                    .and change { Sipity::EntitySpecificResponsibility.count }.by(1)
                                                                                                              .and change { Sipity::WorkflowResponsibility.count }.by(0)
      end

      it 'will be idempotent' do
        builder = lambda do
          described_class.call(
            agents: user,
            roles: role.name,
            entity: entity,
            workflow: workflow,
            workflow_state: workflow_state,
            action_names: action_name
          )
        end
        builder.call
        [:update_attribute, :update_attributes, :update_attributes!, :save, :save!, :update, :update!].each do |method_names|
          expect_any_instance_of(ActiveRecord::Base).not_to receive(method_names)
        end
        builder.call
      end
    end
  end
end
