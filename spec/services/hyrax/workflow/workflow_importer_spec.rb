# frozen_string_literal: true
require "spec_helper"

RSpec.describe Hyrax::Workflow::WorkflowImporter do
  let(:permission_template) { create(:permission_template) }
  let(:data) do
    {
      workflows: [
        {
          name: "ulra_submission",
          label: "This is the label",
          description: "This description could get really long",
          allows_access_grant: true,
          actions: [{
            name: "approve",
            transition_to: "reviewed",
            from_states: [{ names: ["under_review"], roles: ["ulra_reviewing"] }]
          }]
        }
      ]
    }
  end
  let(:validator) { double(call: true) }
  let(:importer) { described_class.new(data: {}, permission_template: permission_template, validator: validator) }

  subject { importer }

  before { described_class.clear_load_errors! }

  describe '#default_validator' do
    subject { importer.send(:default_validator) }

    it { is_expected.to respond_to(:call) }
  end

  describe '#default_schema' do
    subject { importer.send(:default_schema) }

    it { is_expected.to respond_to(:call) }
  end

  it 'validates the data against the schema' do
    subject
    expect(validator).to have_received(:call).with(data: subject.send(:data), schema: subject.send(:schema), logger: subject.send(:logger))
  end

  describe '.load_workflow_for' do
    it 'will assocate the workflows' do
      expect do
        described_class.load_workflow_for(permission_template: permission_template)
      end.to change { Sipity::Workflow.count }
    end
  end

  describe '.generate_from_hash' do
    it 'creates the requisite data from the configuration' do
      number_of_workflows_created = 1
      expect(Hyrax::Workflow::WorkflowPermissionsGenerator).to receive(:call).and_call_original
      expect(Hyrax::Workflow::SipityActionsGenerator).to receive(:call).and_call_original
      result = nil
      expect do
        result = described_class.generate_from_hash(data: data, permission_template: permission_template)
      end.to change { Sipity::Workflow.count }.by(number_of_workflows_created).and(change { permission_template.available_workflows.count }.by(number_of_workflows_created))
      expect(result).to match_array(kind_of(Sipity::Workflow))
      expect(described_class.load_errors).to be_empty
      first_workflow = result.first
      expect(first_workflow.label).to eq "This is the label"
      expect(first_workflow.description).to eq "This description could get really long"
      expect(first_workflow.allows_access_grant?).to be true
    end
  end

  describe 'data generation' do
    let(:logger) { Logger.new(STDOUT) }
    let(:data) { { workflows: [{ name: '', actions: [] }] } }
    let(:importer) { described_class.new(data: data, permission_template: permission_template, logger: logger) }

    describe 'with invalid data' do
      it 'logs the output' do
        expect(logger).to receive(:error).with(kind_of(String))
        expect { importer }.to raise_error(RuntimeError)
      end
    end

    describe 'with very invalid schema' do
      let(:data) { { workflows: [{ name: '' }] } }

      it 'logs the output' do
        expect(logger).to receive(:error).with(kind_of(String))
        expect { importer }.to raise_error(RuntimeError)
      end
    end
  end

  context "when I load JSON twice" do
    let!(:workflow1) { described_class.generate_from_hash(data: data, permission_template: permission_template).first }
    let(:workflow2) { described_class.generate_from_hash(data: data, permission_template: permission_template).first }
    let(:workflow2_errors) { described_class.load_errors }

    context 'with the same data' do
      it "workflow and workflow states do not change" do
        workflow1
        # If the Sipity::WorkflowState IDs or Sipity::Workflow IDs change, we are going to have a serious problem upstream
        expect do
          expect do
            workflow2
          end.not_to change { Sipity::WorkflowState.all.pluck(:id).sort }
        end.not_to change { Sipity::Workflow.all.pluck(:id).sort }
        expect(workflow2).to eq(workflow1)
        expect(workflow2_errors).to be_empty
      end
    end

    context 'with different data' do
      let(:action_name)  { "awesome action" }
      let(:state_name)   { "awesome state" }
      let(:workflow2) { described_class.generate_from_hash(data: updated_data, permission_template: permission_template).first }
      let(:updated_data) do
        {
          workflows: [
            {
              name: workflow_name,
              label: "This is the label for the second json",
              description: "This description could get really long",
              actions: [{
                name: action_name,
                transition_to: state_name,
                from_states: [{ names: ["under_review"], roles: ["ulra_reviewing"] }]
              }]
            }
          ]
        }
      end

      context 'that includes a workflow_name changes' do
        let(:workflow_name) { "awsome workflow" }

        it "creates a new workflow (preserving the old)" do
          expect(workflow2).not_to eq(workflow1)
          expect(Sipity::Workflow.count).to eq(2)
          expect(Sipity::WorkflowState.count).to eq(4)
          expect(workflow2_errors).to be_empty
        end
      end

      context "that keeps the same workflow_name name" do
        let(:workflow_name) { "ulra_submission" }

        it "preserves state names identified in actions > transition_to and actions> from_states > names hash key" do
          expect(workflow2.label).not_to eq(workflow1.label)
          expect(workflow2).to eq(workflow1)
          expect(Sipity::Workflow.count).to eq(1)
          expect(workflow2_errors).to be_empty
          expect(Sipity::WorkflowAction.count).to eq(1)
          expect(Sipity::WorkflowState.count).to eq(2)
        end

        context "when entities are in a state that is no longer included" do
          let(:data) do
            {
              workflows: [
                {
                  name: "ulra_submission",
                  label: "This is the label",
                  description: "This description could get really long",
                  allows_access_grant: true,
                  actions: [{
                    name: "approve",
                    transition_to: "reviewed",
                    from_states: [{ names: ["under_review"], roles: ["ulra_reviewing"] }]
                  }, {
                    name: "decline",
                    transition_to: "declined",
                    from_states: [{ names: ['under_review'], roles: ['ulra_reviewing'] }]
                  }]
                }
              ]
            }
          end
          let(:workflow_state) { workflow1.reload.workflow_states.find_by(name: 'declined') }
          let!(:entity) { Sipity::Entity.create(workflow_state: workflow_state, proxy_for_global_id: "abc123", workflow_id: workflow1.id) }

          it "reports an error and does not update the WorkflowStates" do
            expect do
              expect do
                expect do
                  workflow2
                end.not_to change { Sipity::Workflow.count }
              end.not_to change { Sipity::WorkflowState.count }
            end.not_to change { Sipity::WorkflowAction.count }
            expect(workflow2_errors).to eq(["The workflow: ulra_submission has not been updated.  " \
                                            "You are removing a state: #{workflow_state.name} with " \
                                            "1 entity/ies.  A state may not be removed while it has " \
                                            "active entities!"])
          end
        end
      end
    end
  end

  context 'data generation' do
    let(:invalid_data) do
      {
        workflows: [
          {
            name: "ulra_submission",
            label: "",
            description: "",
            actions: [{ name: "approve", transition_to: "reviewed", from_states: [{ names: ["under_review"], roles: ["ulra_reviewing"] }] }]
          }
        ]
      }
    end

    context 'with incomplete data' do
      it 'will not load any of the data' do
        expect do
          expect do
            expect do
              expect do
                described_class.generate_from_hash(data: invalid_data, permission_template: permission_template)
              end.to raise_error(RuntimeError)
            end.not_to change { Sipity::Workflow.count }
          end.not_to change { Sipity::WorkflowAction.count }
        end.not_to change { Sipity::WorkflowState.count }
      end

      it 'will not amend when new data is invalid' do
        described_class.generate_from_hash(data: data, permission_template: permission_template)
        expect do
          expect do
            expect do
              expect do
                described_class.generate_from_hash(data: invalid_data, permission_template: permission_template)
              end.to raise_error(RuntimeError)
            end.not_to change { Sipity::Workflow.count }
          end.not_to change { Sipity::WorkflowAction.count }
        end.not_to change { Sipity::WorkflowState.count }
      end
    end
  end
end
