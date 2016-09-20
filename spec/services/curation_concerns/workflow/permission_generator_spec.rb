require 'spec_helper'

module CurationConcerns
  module Workflow
    RSpec.describe PermissionGenerator do
      let(:user) { FactoryGirl.create(:user) }
      let(:role) { Sipity::Role.create!(name: 'creating_user') }
      let(:workflow) { Sipity::Workflow.create!(name: 'workflow') }
      let(:workflow_state) { workflow.initial_workflow_state }
      let(:entity) do
        Sipity::Entity.create!(proxy_for: "gid://work/1", workflow: workflow, workflow_state: workflow_state)
      end
      let(:another_entity) do
        Sipity::Entity.create!(proxy_for: "gid://work/2", workflow: workflow, workflow_state: workflow_state)
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
          expect_any_instance_of(ActiveRecord::Base).to_not receive(method_names)
        end
        builder.call
      end

      # The spirit of the test is to make sure that permissions are enforced at the entity level
      # We will need to move things into the Ability class to verify this behavior
      xit 'will build the entity level permissions if an entity is specified' do
        described_class.call(
          agents: user,
          roles: role,
          entity: entity,
          workflow: workflow,
          workflow_state: workflow_state,
          action_names: action_name
        )
        permission_to_action = Policies::Processing::ProcessingEntityPolicy.call(
          user: user, entity: entity, action_to_authorize: action_name
        )
        expect(permission_to_action).to be_truthy

        permission_to_another_entity_action = Policies::Processing::ProcessingEntityPolicy.call(
          user: user, entity: another_entity, action_to_authorize: action_name
        )
        expect(permission_to_another_entity_action).to be_falsey
      end

      # The spirit of the test is to make sure that permissions are enforced at the workflow level
      # We will need to move things into the Ability class to verify this behavior
      xit 'will build the workflow level permissions if no entity is given' do
        described_class.call(
          agents: user,
          roles: role,
          workflow: workflow,
          workflow_state: workflow_state,
          action_names: action_name
        )
        permission_to_action = Policies::Processing::ProcessingEntityPolicy.call(
          user: user, entity: entity, action_to_authorize: action_name
        )
        expect(permission_to_action).to be_truthy

        permission_to_another_entity_action = Policies::Processing::ProcessingEntityPolicy.call(
          user: user, entity: another_entity, action_to_authorize: action_name
        )
        expect(permission_to_another_entity_action).to be_truthy
      end
    end
  end
end
