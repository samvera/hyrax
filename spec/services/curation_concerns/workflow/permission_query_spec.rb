require 'spec_helper'

module CurationConcerns
  module Workflow
    RSpec.describe PermissionQuery, slow_test: true do
      let(:reviewing_user) { FactoryGirl.create(:user) }
      let(:completing_user) { FactoryGirl.create(:user) }
      let(:workflow_config) do
        {
          work_types: [{
            name: 'testing',
            actions: [{
              name: "forward", from_states: [{ names: ["initial"], roles: ["reviewing"] }], transition_to: 'forwarded'
            }, {
              name: "complete", from_states: [{ names: ["forwarded"], roles: ["completing"] }], transition_to: 'completed'
            }]
          }]
        }
      end
      before { CurationConcerns::Workflow::WorkflowImporter.new(data: workflow_config).call }
      let(:sipity_entity) do
        Sipity::Entity.create!(proxy_for_global_id: 'gid://Mock/1',
                               workflow: sipity_workflow,
                               workflow_state: PowerConverter.convert_to_sipity_workflow_state('initial', scope: sipity_workflow)
                              )
      end
      let(:sipity_workflow) { Sipity::Workflow.first }

      describe '#scope_permitted_workflow_actions_available_for_current_state' do
        # NOTE: I am stacking up expectations because these tests are non-trivial to build (lots of database interactions)
        context 'permissions assigned at the workflow level' do
          it 'will retrieve an ActiveRecord::Relation<Sipity::WorkflowAction>' do
            PermissionGenerator.call(roles: 'reviewing', workflow: sipity_workflow, agents: reviewing_user)
            PermissionGenerator.call(roles: 'completing', workflow: sipity_workflow, agents: completing_user)

            forward_action = PowerConverter.convert_to_sipity_action('forward', scope: sipity_workflow)

            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: reviewing_user, entity: sipity_entity)
            ).to eq([forward_action])

            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: completing_user, entity: sipity_entity)
            ).to eq([])

            # Then transition to Sipity::Entity
            sipity_entity.update_attribute(
              :workflow_state, PowerConverter.convert_to_sipity_workflow_state('forwarded', scope: sipity_workflow)
            )

            # Now permissions have changed
            complete_action = PowerConverter.convert_to_sipity_action('complete', scope: sipity_workflow)
            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: reviewing_user, entity: sipity_entity)
            ).to eq([])
            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: completing_user, entity: sipity_entity)
            ).to eq([complete_action])
          end
        end

        # NOTE: I am stacking up expectations because these tests are non-trivial to build (lots of database interactions)
        context 'permissions assigned at the entity level' do
          it 'will retrieve an ActiveRecord::Relation<Sipity::WorkflowAction>' do
            PermissionGenerator.call(roles: 'reviewing', entity: sipity_entity, workflow: sipity_workflow, agents: reviewing_user)
            PermissionGenerator.call(roles: 'completing', entity: sipity_entity, workflow: sipity_workflow, agents: completing_user)
            forward_action = PowerConverter.convert_to_sipity_action('forward', scope: sipity_workflow)
            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: reviewing_user, entity: sipity_entity)
            ).to eq([forward_action])
            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: completing_user, entity: sipity_entity)
            ).to eq([])

            # Then transition to Sipity::Entity
            sipity_entity.update_attribute(
              :workflow_state, PowerConverter.convert_to_sipity_workflow_state('forwarded', scope: sipity_workflow)
            )

            # Now permissions have changed
            complete_action = PowerConverter.convert_to_sipity_action('complete', scope: sipity_workflow)
            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: reviewing_user, entity: sipity_entity)
            ).to eq([])
            expect(
              described_class.scope_permitted_workflow_actions_available_for_current_state(user: completing_user, entity: sipity_entity)
            ).to eq([complete_action])
          end
        end
      end
    end
  end
end
