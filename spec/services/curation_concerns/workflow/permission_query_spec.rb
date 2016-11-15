require 'spec_helper'

module CurationConcerns
  module Workflow
    RSpec.describe PermissionQuery, slow_test: true, no_clean: true do
      let(:reviewing_user) { create(:user) }
      let(:completing_user) { create(:user) }
      let(:workflow_config) do
        {
          workflows: [{
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
        Sipity::Entity.create!(proxy_for_global_id: 'gid://internal/Mock/1',
                               workflow: sipity_workflow,
                               workflow_state: PowerConverter.convert_to_sipity_workflow_state('initial', scope: sipity_workflow)
                              )
      end
      let(:sipity_workflow) { Sipity::Workflow.find_by(name: 'testing') }

      def expect_actions_for(user:, entity:, actions:)
        actions = Array.wrap(actions).map { |action| PowerConverter.convert_to_sipity_action(action, scope: entity.workflow) }
        expect(described_class.scope_permitted_workflow_actions_available_for_current_state(user: user, entity: entity)).to eq(actions)
      end

      def expect_agents_for(agents:, entity:, role:)
        agents = Array.wrap(agents).map { |agent| PowerConverter.convert_to_sipity_agent(agent) }
        expect(described_class.scope_agents_associated_with_entity_and_role(role: role, entity: entity)).to eq(agents)
      end

      def expect_roles_for(entity:, roles:)
        roles = Array.wrap(roles).map { |role| PowerConverter.convert_to_sipity_role(role) }
        expect(described_class.scope_roles_associated_with_the_given_entity(entity: entity)).to eq(roles)
      end

      def expect_users_for(entity:, roles:, users:)
        expect(described_class.scope_users_for_entity_and_roles(entity: entity, roles: roles)).to eq(Array.wrap(users))
      end

      def expect_to_be_authorized(user:, entity:, action:, message: 'should be authorized')
        expect(described_class.authorized_for_processing?(user: user, entity: entity, action: action)).to be_truthy, message
      end

      def expect_to_not_be_authorized(user:, entity:, action:, message: 'should not be authorized')
        expect(described_class.authorized_for_processing?(user: user, entity: entity, action: action)).to be_falsey, message
      end

      def expect_entities_for(user:, entities:)
        entities = Array.wrap(entities).map { |entity| PowerConverter.convert(entity, to: :sipity_entity) }
        expect(described_class.scope_entities_for_the_user(user: user)).to eq(entities)
      end

      describe 'permissions assigned at the workflow level' do
        let(:reviewing_group_member) { create(:user) }
        let(:reviewing_group) { Group.new('librarians') }
        before do
          allow(reviewing_group_member).to receive(:groups).and_return(['librarians'])
          PermissionGenerator.call(roles: 'reviewing', workflow: sipity_workflow, agents: reviewing_user)
          PermissionGenerator.call(roles: 'reviewing', workflow: sipity_workflow, agents: reviewing_group)
          PermissionGenerator.call(roles: 'completing', workflow: sipity_workflow, agents: completing_user)
        end

        it 'will fullfil the battery of tests (of which they are nested because setup is expensive)' do
          expect_agents_for(entity: sipity_entity, role: 'reviewing', agents: [reviewing_user, reviewing_group])
          expect_agents_for(entity: sipity_entity, role: 'completing', agents: [completing_user])

          expect_actions_for(user: reviewing_user, entity: sipity_entity, actions: ['forward'])
          expect_actions_for(user: reviewing_group_member, entity: sipity_entity, actions: ['forward'])
          expect_actions_for(user: completing_user, entity: sipity_entity, actions: [])

          expect_users_for(users: reviewing_user, entity: sipity_entity, roles: 'reviewing')
          expect_users_for(users: completing_user, entity: sipity_entity, roles: 'completing')

          expect_entities_for(user: reviewing_user, entities: [sipity_entity])
          expect_entities_for(user: completing_user, entities: [])

          expect_roles_for(entity: sipity_entity, roles: ['reviewing', 'completing'])

          expect_to_be_authorized(user: reviewing_user, entity: sipity_entity, action: 'forward')
          expect_to_not_be_authorized(user: reviewing_user, entity: sipity_entity, action: 'complete')
          expect_to_not_be_authorized(user: completing_user, entity: sipity_entity, action: 'forward')
          expect_to_not_be_authorized user: completing_user, entity: sipity_entity, action: 'complete',
                                      message: 'should be unauthorized because the action is not available in this state'

          # Then transition to Sipity::Entity
          sipity_entity.update_attribute(
            :workflow_state, PowerConverter.convert_to_sipity_workflow_state('forwarded', scope: sipity_workflow)
          )

          # Now permissions have changed
          expect_actions_for(user: reviewing_user, entity: sipity_entity, actions: [])
          expect_actions_for(user: completing_user, entity: sipity_entity, actions: ['complete'])

          expect_to_not_be_authorized user: reviewing_user, entity: sipity_entity, action: 'forward',
                                      message: 'should be unauthorized because the action is not available in this state'
          expect_to_not_be_authorized(user: reviewing_user, entity: sipity_entity, action: 'complete')
          expect_to_not_be_authorized(user: completing_user, entity: sipity_entity, action: 'forward')
          expect_to_be_authorized(user: completing_user, entity: sipity_entity, action: 'complete')

          expect_entities_for(user: reviewing_user, entities: [])
          expect_entities_for(user: completing_user, entities: [sipity_entity])
        end
      end

      # NOTE: I am stacking up expectations because these tests are non-trivial to build (lots of database interactions)
      describe 'permissions assigned at the entity level' do
        it 'will fullfil the battery of tests (of which they are nested because setup is expensive)' do
          PermissionGenerator.call(roles: 'reviewing', entity: sipity_entity, workflow: sipity_workflow, agents: reviewing_user)
          PermissionGenerator.call(roles: 'completing', entity: sipity_entity, workflow: sipity_workflow, agents: completing_user)

          expect_agents_for(entity: sipity_entity, role: 'reviewing', agents: [reviewing_user])
          expect_agents_for(entity: sipity_entity, role: 'completing', agents: [completing_user])

          expect_actions_for(user: reviewing_user, entity: sipity_entity, actions: ['forward'])
          expect_actions_for(user: completing_user, entity: sipity_entity, actions: [])

          expect_users_for(users: reviewing_user, entity: sipity_entity, roles: 'reviewing')
          expect_users_for(users: completing_user, entity: sipity_entity, roles: 'completing')

          expect_entities_for(user: reviewing_user, entities: [sipity_entity])
          expect_entities_for(user: completing_user, entities: [])

          expect_roles_for(entity: sipity_entity, roles: ['reviewing', 'completing'])

          expect_to_be_authorized(user: reviewing_user, entity: sipity_entity, action: 'forward')
          expect_to_not_be_authorized(user: reviewing_user, entity: sipity_entity, action: 'complete')
          expect_to_not_be_authorized(user: completing_user, entity: sipity_entity, action: 'forward')
          expect_to_not_be_authorized user: completing_user, entity: sipity_entity, action: 'complete',
                                      message: 'should be unauthorized because the action is not available in this state'

          # Then transition to Sipity::Entity
          sipity_entity.update_attribute(
            :workflow_state, PowerConverter.convert_to_sipity_workflow_state('forwarded', scope: sipity_workflow)
          )

          # Now permissions have changed
          expect_actions_for(user: reviewing_user, entity: sipity_entity, actions: [])
          expect_actions_for(user: completing_user, entity: sipity_entity, actions: ['complete'])

          expect_to_not_be_authorized user: reviewing_user, entity: sipity_entity, action: 'forward',
                                      message: 'should be unauthorized because the action is not available in this state'
          expect_to_not_be_authorized(user: reviewing_user, entity: sipity_entity, action: 'complete')
          expect_to_not_be_authorized(user: completing_user, entity: sipity_entity, action: 'forward')
          expect_to_be_authorized(user: completing_user, entity: sipity_entity, action: 'complete')

          expect_entities_for(user: reviewing_user, entities: [])
          expect_entities_for(user: completing_user, entities: [sipity_entity])
        end
      end

      describe '.scope_processing_agents_for', no_clean: true do
        context 'when user is not persisted' do
          subject { described_class.scope_processing_agents_for(user: ::User.new) }
          it { is_expected.to eq([]) }
        end
        context 'when user is non-trivial' do
          subject { described_class.scope_processing_agents_for(user: nil) }
          it { is_expected.to eq([]) }
        end
        context 'when user is persisted' do
          let(:user) { create(:user) }
          subject { described_class.scope_processing_agents_for(user: user) }
          it 'will equal [kind_of(Sipity::Agent)]' do
            is_expected.to contain_exactly(PowerConverter.convert_to_sipity_agent(user),
                                           PowerConverter.convert_to_sipity_agent(Group.new('registered')))
          end
        end
      end
    end
  end
end
