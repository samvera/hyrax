# frozen_string_literal: true
module Hyrax
  module Workflow
    RSpec.describe PermissionQuery, slow_test: true do
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

      let(:sipity_entity) do
        Sipity::Entity.create!(proxy_for_global_id: 'gid://internal/Mock/1',
                               workflow: sipity_workflow,
                               workflow_state: Sipity::WorkflowState('initial', sipity_workflow))
      end
      let(:sipity_workflow) { create(:workflow, name: 'testing') }

      before { Hyrax::Workflow::WorkflowImporter.generate_from_hash(data: workflow_config, permission_template: sipity_workflow.permission_template) }

      def expect_actions_for(user:, entity:, actions:)
        actions = Array.wrap(actions).map { |action| Sipity::WorkflowAction(action, entity.workflow) }
        expect(described_class.scope_permitted_workflow_actions_available_for_current_state(user: user, entity: entity)).to eq(actions)
      end

      def expect_agents_for(agents:, entity:, role:)
        agents = Array.wrap(agents).map { |agent| Sipity::Agent(agent) }
        expect(described_class.scope_agents_associated_with_entity_and_role(role: role, entity: entity)).to contain_exactly(*agents)
      end

      def expect_roles_for(entity:, roles:)
        roles = Array.wrap(roles).map { |role| Sipity::Role.find_or_create_by(name: role) }
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

      def expect_entities_for(user:, entities:, page: 1, per_page: 1)
        entities = Array.wrap(entities).map { |entity| Sipity::Entity(entity) }
        expect(described_class.scope_entities_for_the_user(user: user, page: page, per_page: per_page)).to eq(entities)
      end

      describe 'entity_responsibilities' do
        it 'is a Sipity::EntitySpecificResponsibility.arel_table' do
          expect(described_class.entity_responsibilities).to be_an_instance_of Arel::Table
        end
      end

      describe 'workflow_responsibilities' do
        it 'is a Sipity::WorkflowResponsibility.arel_table' do
          expect(described_class.workflow_responsibilities).to be_an_instance_of Arel::Table
        end
      end

      describe 'workflow_roles' do
        it 'is a Sipity::WorkflowRole.arel_table' do
          expect(described_class.workflow_roles).to be_an_instance_of Arel::Table
        end
      end

      describe 'scope_entities_for_the_user' do
        context 'with multiple entities in different states' do
          let(:sipity_entity2) do
            Sipity::Entity.create!(proxy_for_global_id: 'gid://internal/Mock/2',
                                   workflow: sipity_workflow,
                                   workflow_state: Sipity::WorkflowState('forwarded', sipity_workflow))
          end

          before do
            # Give reviewing_user permission to all workflow states
            PermissionGenerator.call(roles: 'reviewing', workflow: sipity_workflow, agents: reviewing_user)
            PermissionGenerator.call(roles: 'completing', workflow: sipity_workflow, agents: reviewing_user)
          end

          it 'filters entities by provided workflow states' do
            # Not filtered by workflow state
            both_entities = Array.wrap([sipity_entity, sipity_entity2]).map { |entity| Sipity::Entity(entity) }
            expect(described_class.scope_entities_for_the_user(user: reviewing_user, workflow_state_filter: nil)).to eq(both_entities)
            # filtered by a workflow state
            initial_entities = Array.wrap([sipity_entity]).map { |entity| Sipity::Entity(entity) }
            expect(described_class.scope_entities_for_the_user(user: reviewing_user, workflow_state_filter: 'initial')).to eq(initial_entities)
            # Negated filtered by a workflow state
            forwarded_entities = Array.wrap([sipity_entity2]).map { |entity| Sipity::Entity(entity) }
            expect(described_class.scope_entities_for_the_user(user: reviewing_user, workflow_state_filter: '!initial')).to eq(forwarded_entities)
            # filtered directly by forwarded workflow state
            expect(described_class.scope_entities_for_the_user(user: reviewing_user, workflow_state_filter: 'forwarded')).to eq(forwarded_entities)
          end
        end
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
          sipity_entity.update!(
            workflow_state: Sipity::WorkflowState('forwarded', sipity_workflow)
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

        context 'with multiple entities' do
          let(:sipity_entity2) do
            Sipity::Entity.create!(proxy_for_global_id: 'gid://internal/Mock/2',
                                   workflow: sipity_workflow,
                                   workflow_state: Sipity::WorkflowState('initial', sipity_workflow))
          end

          it 'will fullfil the battery of tests (of which they are nested because setup is expensive)' do
            expect_agents_for(entity: sipity_entity, role: 'reviewing', agents: [reviewing_user, reviewing_group])
            expect_agents_for(entity: sipity_entity, role: 'completing', agents: [completing_user])
            expect_agents_for(entity: sipity_entity2, role: 'reviewing', agents: [reviewing_user, reviewing_group])
            expect_agents_for(entity: sipity_entity2, role: 'completing', agents: [completing_user])

            expect_actions_for(user: reviewing_user, entity: sipity_entity, actions: ['forward'])
            expect_actions_for(user: reviewing_group_member, entity: sipity_entity, actions: ['forward'])
            expect_actions_for(user: completing_user, entity: sipity_entity, actions: [])
            expect_actions_for(user: reviewing_user, entity: sipity_entity, actions: ['forward'])
            expect_actions_for(user: reviewing_group_member, entity: sipity_entity2, actions: ['forward'])
            expect_actions_for(user: completing_user, entity: sipity_entity2, actions: [])

            expect_users_for(users: reviewing_user, entity: sipity_entity, roles: 'reviewing')
            expect_users_for(users: completing_user, entity: sipity_entity, roles: 'completing')

            expect_entities_for(user: reviewing_user, entities: [sipity_entity])
            expect_entities_for(user: completing_user, entities: [])
            # Test paging of entities query
            expect_entities_for(user: reviewing_user, entities: [sipity_entity], page: 1, per_page: 1)
            expect_entities_for(user: reviewing_user, entities: [sipity_entity2], page: 2, per_page: 1)
            expect_entities_for(user: reviewing_user, entities: [sipity_entity, sipity_entity2], page: 1, per_page: 2)
            expect_entities_for(user: completing_user, entities: [])

            expect_roles_for(entity: sipity_entity, roles: ['reviewing', 'completing'])
            expect_roles_for(entity: sipity_entity2, roles: ['reviewing', 'completing'])
          end
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
          sipity_entity.update!(
            workflow_state: Sipity::WorkflowState('forwarded', sipity_workflow)
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

      describe '.scope_processing_agents_for' do
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

          before do
            allow(user).to receive(:groups).and_return(['librarians'])
          end

          subject { described_class.scope_processing_agents_for(user: user) }

          it 'will equal [kind_of(Sipity::Agent)]' do
            is_expected.to contain_exactly(Sipity::Agent(user),
                                           Sipity::Agent(Group.new('librarians')))
          end
        end
      end
    end
  end
end
