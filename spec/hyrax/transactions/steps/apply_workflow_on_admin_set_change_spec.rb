# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ApplyWorkflowOnAdminSetChange, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }

  let(:depositor) { FactoryBot.create(:user) }

  let(:old_admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template) }
  let(:new_admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template) }

  let(:old_template) { Hyrax::PermissionTemplate.find_by(source_id: old_admin_set.id.to_s) }
  let(:new_template) { Hyrax::PermissionTemplate.find_by(source_id: new_admin_set.id.to_s) }

  let(:old_workflow_spec) { single_state_workflow('old_workflow', states: %w[pending approved]) }
  let(:new_workflow_spec) { single_state_workflow('new_workflow', states: %w[pending approved]) }

  let(:old_workflow) do
    Hyrax::Workflow::WorkflowImporter.generate_from_hash(
      data: old_workflow_spec.as_json,
      permission_template: old_template
    )
    Sipity::Workflow.where(permission_template: old_template, name: 'old_workflow').first
  end

  let(:new_workflow) do
    Hyrax::Workflow::WorkflowImporter.generate_from_hash(
      data: new_workflow_spec.as_json,
      permission_template: new_template
    )
    Sipity::Workflow.where(permission_template: new_template, name: 'new_workflow').first
  end

  def single_state_workflow(name, states:)
    actions = [{ name: 'ingest', from_states: [], transition_to: states.first }]
    states.each_cons(2) do |from, to|
      actions << { name: "advance_to_#{to}",
                   from_states: [{ names: [from], roles: ['approving'] }],
                   transition_to: to }
    end
    { workflows: [{ name: name, label: name, description: name, actions: actions }] }
  end

  # Builds a work that has been deposited into `original_admin_set` (where the
  # WorkflowListener will create the Sipity::Entity at deposit time), then
  # rewrites the work's admin_set_id to `new_admin_set` and stamps the
  # `previous_admin_set_id` singleton attribute, as the Save step would.
  def transferred_work(original_admin_set:, new_admin_set:)
    work = FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set,
                                      admin_set: original_admin_set,
                                      depositor: depositor.user_key)
    work.admin_set_id = new_admin_set.id
    old_id = original_admin_set.id.to_s
    work.define_singleton_method(:previous_admin_set_id) { old_id }
    work
  end

  context 'when admin set has not changed' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, depositor: depositor.user_key) }

    it 'returns success without touching any entity' do
      expect { step.call(work) }.not_to change(Sipity::Entity, :count)
      expect(step.call(work)).to be_success
    end
  end

  context 'when admin set changed and both admin sets are workflow-managed' do
    let(:work) { transferred_work(original_admin_set: old_admin_set, new_admin_set: new_admin_set) }

    before do
      Sipity::Workflow.activate!(permission_template: old_template, workflow_id: old_workflow.id)
      Sipity::Workflow.activate!(permission_template: new_template, workflow_id: new_workflow.id)
      work # trigger creation while old_workflow is the active workflow for the original admin set
    end

    it 'moves the entity to the new workflow at the same-named state' do
      result = step.call(work)

      expect(result).to be_success
      entity = Sipity::Entity.find_by(proxy_for_global_id: Hyrax::GlobalID(work).to_s)
      expect(entity.workflow_id).to eq new_workflow.id
      expect(entity.workflow_state_name).to eq 'pending'
    end

    context 'when the prior state name does not exist on the new workflow' do
      let(:new_workflow_spec) { single_state_workflow('new_workflow', states: %w[fresh published]) }

      it 'falls back to the new workflow initial state and warns' do
        expect(Hyrax.logger).to receive(:warn).with(/Falling back to the initial state/)

        step.call(work)

        entity = Sipity::Entity.find_by(proxy_for_global_id: Hyrax::GlobalID(work).to_s)
        expect(entity.workflow_id).to eq new_workflow.id
        expect(entity.workflow_state).to eq new_workflow.initial_workflow_state
      end
    end

    it 'rebuilds the depositor entity-specific responsibility against the new workflow' do
      step.call(work)

      entity = Sipity::Entity.find_by(proxy_for_global_id: Hyrax::GlobalID(work).to_s)
      depositor_agent = Sipity::Agent(depositor)
      responsibilities = entity.entity_specific_responsibilities
                               .where(agent_id: depositor_agent.id)
                               .includes(:workflow_role)

      expect(responsibilities.size).to eq 1
      expect(responsibilities.first.workflow_role.workflow_id).to eq new_workflow.id
    end
  end

  context 'when the new admin set is not workflow-managed' do
    let(:work) { transferred_work(original_admin_set: old_admin_set, new_admin_set: new_admin_set) }

    before do
      Sipity::Workflow.activate!(permission_template: old_template, workflow_id: old_workflow.id)
      work # creates entity on old_workflow via the deposit listener
    end

    it 'leaves the existing entity in place pointing at the prior workflow' do
      result = step.call(work)

      expect(result).to be_success
      entity = Sipity::Entity.find_by(proxy_for_global_id: Hyrax::GlobalID(work).to_s)
      expect(entity.workflow_id).to eq old_workflow.id
      expect(entity.workflow_state_name).to eq 'pending'
    end
  end

  context 'when transferring between two workflow-managed admin sets with different managers' do
    let(:user_one) { FactoryBot.create(:user) }
    let(:user_two) { FactoryBot.create(:user) }
    let(:work) { transferred_work(original_admin_set: old_admin_set, new_admin_set: new_admin_set) }

    before do
      Hyrax.config.persist_registered_roles!
      Sipity::Workflow.activate!(permission_template: old_template, workflow_id: old_workflow.id)
      Sipity::Workflow.activate!(permission_template: new_template, workflow_id: new_workflow.id)
      grant_manage_responsibilities(workflow: old_workflow, user: user_one)
      grant_manage_responsibilities(workflow: new_workflow, user: user_two)
      work # creates entity on old_workflow via the deposit listener
    end

    def grant_manage_responsibilities(workflow:, user:)
      magic_roles = Sipity::Role.where(name: Hyrax::RoleRegistry.new.role_names)
      Hyrax::Workflow::PermissionGenerator.call(agents: user, roles: magic_roles, workflow: workflow)
    end

    def actions_for(user:, entity:)
      Hyrax::Workflow::PermissionQuery
        .scope_permitted_workflow_actions_available_for_current_state(user: user, entity: entity)
    end

    it 'flips actionable roles from the old admin set manager to the new admin set manager' do
      entity = Sipity::Entity.find_by(proxy_for_global_id: Hyrax::GlobalID(work).to_s)
      expect(actions_for(user: user_one, entity: entity)).to be_any
      expect(actions_for(user: user_two, entity: entity)).to be_none

      step.call(work)

      entity.reload
      expect(actions_for(user: user_one, entity: entity)).to be_none
      expect(actions_for(user: user_two, entity: entity)).to be_any
    end
  end

  context 'when the work has no Sipity::Entity yet' do
    let(:work) do
      # Create the work before either admin set has an active workflow so the
      # deposit listener has nothing to attach to.
      w = FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set,
                                     admin_set: old_admin_set,
                                     depositor: depositor.user_key)
      w.admin_set_id = new_admin_set.id
      old_id = old_admin_set.id.to_s
      w.define_singleton_method(:previous_admin_set_id) { old_id }
      w
    end

    before do
      work
      Sipity::Workflow.activate!(permission_template: new_template, workflow_id: new_workflow.id)
    end

    it 'is a no-op and does not create an entity' do
      expect { step.call(work) }.not_to change(Sipity::Entity, :count)
      expect(step.call(work)).to be_success
    end
  end
end
