# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::WorkflowListener do
  subject(:listener) { described_class.new }
  let(:data)         { { object: resource, user: user } }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:resource)     { FactoryBot.valkyrie_create(:hyrax_work) }
  let(:user)         { FactoryBot.create(:user) }

  let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, with_permission_template: true) }
  let(:permission_template) { Hyrax::PermissionTemplate.find_by!(source_id: admin_set.id.to_s) }

  shared_examples 'logs a sipity error' do
    it 'does not create sipity entity' do
      expect { listener.on_object_deposited(event) }
        .not_to change { Sipity::Entity.count }
    end

    it 'logs an error' do
      expect(Hyrax.logger).to receive(:error)

      listener.on_object_deposited(event)
    end
  end

  describe '#on_object_deposited' do
    let(:event_type) { :on_object_deposited }

    context 'without an admin set id method' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_resource) }

      it_behaves_like 'logs a sipity error'
    end

    context 'with a nil/empty admin_set_id' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }

      it_behaves_like 'logs a sipity error'
    end

    context 'with no user' do
      let(:user) { nil }

      it 'logs a warning' do
        expect(Hyrax.logger).to receive(:warn)

        listener.on_object_deposited(event)
      end

      it 'does not create sipity entity' do
        expect { listener.on_object_deposited(event) }
          .not_to change { Sipity::Entity.count }
      end
    end

    context 'with an admin_set_id, but no permission template' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id) }
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

      it_behaves_like 'logs a sipity error'
    end

    context 'with an admin_set_id and permission template, but no workflow' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id) }

      it_behaves_like 'logs a sipity error'
    end

    context 'with an admin_set_id and permission template, and an inactive workflow' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id) }

      before do
        FactoryBot.create(:workflow, active: false, permission_template: permission_template)
      end

      it_behaves_like 'logs a sipity error'
    end

    context 'with an admin_set_id, permission template and an active workflow, but no action' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id) }

      before do
        FactoryBot.create(:workflow, active: true, permission_template: permission_template)
      end

      it_behaves_like 'logs a sipity error'
    end

    context 'with an admin_set_id, permission template and an active workflow and a start action' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id) }
      let(:state) { Sipity::WorkflowState.create!(workflow: workflow, name: 'first_state') }
      let(:workflow) { FactoryBot.create(:workflow, active: true, permission_template: permission_template) }

      before do
        Sipity::WorkflowAction.create!(workflow: workflow, name: 'start', resulting_workflow_state: state)
      end

      it 'initializes the workflow (runs first action, resulting in a state)' do
        listener.on_object_deposited(event)

        expect(Sipity::Entity(resource).workflow_state).to eq state
      end
    end

    context 'theres a hole in the bottom of the sea' do
      it_behaves_like 'logs a sipity error'
    end
  end
end
