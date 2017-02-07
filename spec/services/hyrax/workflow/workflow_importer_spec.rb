require "spec_helper"

RSpec.describe Hyrax::Workflow::WorkflowImporter do
  let(:path) { double(read: json) }
  let(:permission_template) { create(:permission_template) }
  let(:json) do
    doc = <<-HERE
    {
      "workflows": [
        {
          "name": "ulra_submission",
          "label": "This is the label",
          "description": "This description could get really long",
          "actions": [{
            "name": "approve",
            "transition_to": "reviewed",
            "from_states": [{ "names": ["under_review"], "roles": ["ulra_reviewing"] }]
          }]
        }
      ]
    }
    HERE
    doc.strip
  end
  let(:validator) { double(call: true) }
  let(:importer) { described_class.new(data: {}, permission_template: permission_template, validator: validator) }
  subject { importer }

  context '#default_validator' do
    subject { importer.send(:default_validator) }
    it { is_expected.to respond_to(:call) }
  end

  context '#default_schema' do
    subject { importer.send(:default_schema) }
    it { is_expected.to respond_to(:call) }
  end

  it 'validates the data against the schema' do
    subject
    expect(validator).to have_received(:call).with(data: subject.send(:data), schema: subject.send(:schema))
  end

  context 'data generation' do
    before do
      described_class.clear_load_errors!
    end

    it 'creates the requisite data from the configuration' do
      number_of_workflows_created = 1
      expect(Hyrax::Workflow::WorkflowPermissionsGenerator).to receive(:call).and_call_original
      expect(Hyrax::Workflow::SipityActionsGenerator).to receive(:call).and_call_original
      result = nil
      expect do
        result = described_class.generate_from_json_file(path: path, permission_template: permission_template)
      end.to change { Sipity::Workflow.count }.by(number_of_workflows_created).and(change { permission_template.workflows.count }.by(number_of_workflows_created))
      expect(result).to match_array(kind_of(Sipity::Workflow))
      expect(described_class.load_errors).to be_empty
      expect(result.first.label).to eq "This is the label"
      expect(result.first.description).to eq "This description could get really long"
    end
  end
  context "when I load twice" do
    let!(:workflow1) { described_class.generate_from_json_file(path: path, permission_template: permission_template).first }
    let(:workflow2) { described_class.generate_from_json_file(path: path, permission_template: permission_template).first }
    let(:workflow2_errors) { described_class.load_errors }
    it "creates the same results" do
      expect(workflow2).to eq(workflow1)
      expect(workflow2_errors).to be_empty
    end
    context "When the json changes" do
      let(:workflow_name) { "awsome workflow" }
      let(:action_name)  { "awesome action" }
      let(:state_name)   { "awesome state" }
      let(:second_path) { double(read: json2) }
      let(:workflow2) { described_class.generate_from_json_file(path: second_path, permission_template: permission_template).first }
      let(:json2) do
        doc = <<-HERE
        {
          "workflows": [
            {
              "name": "#{workflow_name}",
              "label": "This is the label for the second json",
              "description": "This description could get really long",
              "actions": [{
                "name": "#{action_name}",
                "transition_to": "#{state_name}",
                "from_states": [{ "names": ["under_review"], "roles": ["ulra_reviewing"] }]
              }]
            }
          ]
        }
        HERE
        doc.strip
      end
      it "creates another workflow" do
        expect(workflow2).not_to eq(workflow1)
        expect(Sipity::Workflow.count).to eq(2)
        expect(workflow2_errors).to be_empty
      end
      context "when the workflow name stays the same" do
        let(:workflow_name) { "ulra_submission" }
        it "modifies the same workflow" do
          expect(workflow2.label).not_to eq(workflow1.label)
          expect(Sipity::Workflow.count).to eq(1)
          expect(workflow2_errors).to be_empty
          expect(Sipity::WorkflowAction.count).to eq(1)
          expect(Sipity::WorkflowState.count).to eq(1)
        end
        context "when entities are in the state" do
          let(:workflow_state) { workflow1.reload.workflow_states.first }
          let!(:entity) { Sipity::Entity.create(workflow_state: workflow_state, proxy_for_global_id: "abc123", workflow_id: workflow1.id) }
          it "can not modify the same workflow" do
            expect(workflow2.label).to eq(workflow1.label)
            expect(Sipity::Workflow.count).to eq(1)
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
    let(:amending_with_invalid_data) do
      {
        workflows: [
          {
            name: "ulra_submission",
            label: "",
            description: "",
            actions: [
              {
                name: "approve", transition_to: "reviewed", from_states: [{ names: ["under_review"], roles: ["ulra_reviewing"] }]
              }, {
                name: "something", transition_to: "somewhere", from_states: [{ names: ["under_review"], roles: ["ulra_reviewing"] }]
              }
            ]
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
        described_class.generate_from_json_file(path: path, permission_template: permission_template)
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
