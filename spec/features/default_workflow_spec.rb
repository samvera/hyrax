# frozen_string_literal: true
RSpec.describe 'The default Hyrax workflow', type: :feature, valkyrie_adapter: :test_adapter do
  let(:depositor) { FactoryBot.create(:user) }

  let(:work) do
    FactoryBot.valkyrie_create(:hyrax_work,
                               :with_default_admin_set,
                               state: Hyrax::ResourceStatus::INACTIVE)
  end

  describe 'initializing the workflow', :clean_repo do
    let(:attributes) { :LEGACY_UNUSED_ARGUMENT_WITH_NO_KNOWN_USE_CASE_SHOULD_NEVER_BE_REQUIRED }
    let(:workflow_factory) { Hyrax::Workflow::WorkflowFactory }

    before do
      admin_set_id = Hyrax::EnsureWellFormedAdminSetService.call
      begin
        Sipity::Workflow.find_active_workflow_for(admin_set_id: admin_set_id)
      rescue NoActiveWorkflowError => _
        Hyrax::Workflow::WorkflowImporter.load_workflows
      end
    end

    it 'sets state to "deposited"' do
      workflow_factory.create(work, attributes, depositor)

      expect(Sipity::Entity(work).workflow_state).to have_attributes name: 'deposited'
    end

    it 'activates work' do
      expect { workflow_factory.create(work, attributes, depositor) }
        .to change { work.state }
        .from(Hyrax::ResourceStatus::INACTIVE)
        .to Hyrax::ResourceStatus::ACTIVE
    end

    context 'with a depositor' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_default_admin_set, depositor: depositor.user_key) }

      it 'grants edit to the depositor' do
        expect { workflow_factory.create(work, attributes, depositor) }
          .to change { Hyrax::AccessControlList(work).permissions }
          .to include(have_attributes(mode: :edit, agent: depositor.user_key))
      end
    end
  end
end
