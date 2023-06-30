# frozen_string_literal: true

RSpec.describe Hyrax::Workflow::ActionableObjects do
  subject(:service) { described_class.new(user: user) }
  let(:user) { FactoryBot.create(:user) }

  describe '#each' do
    it 'is empty by default' do
      expect(service.each).to be_none
    end

    context 'with objects in workflow' do
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }
      let(:objects) do
        [FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id),
         FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id),
         FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id)]
      end

      let(:permission_template) do
        Hyrax::PermissionTemplate
          .find_or_create_by(source_id: admin_set.id.to_s)
      end

      let(:workflow) do
        Hyrax::Workflow::WorkflowImporter
          .generate_from_hash(data: workflow_spec.as_json,
                              permission_template: permission_template)
        Sipity::Workflow.last
      end

      let(:workflow_spec) do
        {
          workflows: [
            {
              name: "go_with_the_floe",
              label: "Testing out the workflow ",
              description: "A single-step workflow for the test suite",
              actions: [
                {
                  name: "ingest",
                  from_states: [],
                  transition_to: "needs_attention"
                },
                {
                  name: "two_step",
                  from_states: [
                    {
                      names: ["needs_attention"],
                      roles: ["disapproving"]
                    }
                  ],
                  transition_to: "not_the_magic_name",
                  methods: [
                    "Hyrax::Workflow::ActivateObject"
                  ]
                }
              ]
            }
          ]
        }
      end

      before do
        Sipity::Workflow.activate!(permission_template: permission_template,
                                   workflow_id: workflow.id)

        objects.each { |o| Hyrax::Workflow::WorkflowFactory.create(o, {}, user) }
      end

      it 'is empty with no user actions' do
        expect(service.each).to be_none
      end

      context 'and user available actions' do
        before do
          agent = Sipity::Agent(user)

          Sipity::WorkflowRole.where(workflow_id: workflow.id).each do |wf_role|
            Sipity::WorkflowResponsibility.find_or_create_by!(agent_id: agent.id, workflow_role_id: wf_role.id)
            Sipity::WorkflowResponsibility.find_or_create_by!(agent_id: agent.id, workflow_role_id: wf_role.id)
          end
        end

        it 'lists the objects' do
          expect(service.map(&:id)).to contain_exactly(*objects.map(&:id))
        end

        it 'supports pagination' do
          service.per_page = 2
          service.page = 1
          expect(service.map(&:id)).to contain_exactly(*objects[0..1].map(&:id))
          service.page = 2
          expect(service.map(&:id)).to contain_exactly(*objects[2..2].map(&:id))
        end

        it 'supports filtering by state' do
          service.workflow_state_filter = 'needs_attention'
          expect(service.map(&:id)).to contain_exactly(*objects.map(&:id))
          service.workflow_state_filter = 'nope'
          expect(service.map(&:id)).to be_empty
        end

        it 'includes the workflow states' do
          expect(service.map(&:workflow_state))
            .to contain_exactly('needs_attention',
                                'needs_attention',
                                'needs_attention')
        end
      end
    end
  end
end
