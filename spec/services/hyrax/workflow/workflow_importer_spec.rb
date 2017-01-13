require "spec_helper"

RSpec.describe Hyrax::Workflow::WorkflowImporter do
  let(:path) { double(read: json) }
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

  subject { described_class.new(data: {}, validator: validator) }

  its(:default_validator) { is_expected.to respond_to(:call) }
  its(:default_schema) { is_expected.to respond_to(:call) }

  it 'validates the data against the schema' do
    subject
    expect(validator).to have_received(:call).with(data: subject.send(:data), schema: subject.send(:schema))
  end

  context 'data generation' do
    it 'creates the requisite data from the configuration' do
      expect(Hyrax::Workflow::WorkflowPermissionsGenerator).to receive(:call).and_call_original
      expect(Hyrax::Workflow::SipityActionsGenerator).to receive(:call).and_call_original
      result = nil
      expect do
        result = described_class.generate_from_json_file(path: path)
      end.to change { Sipity::Workflow.count }.by(1)
      expect(result).to match_array(kind_of(Sipity::Workflow))
      expect(result.first.label).to eq "This is the label"
      expect(result.first.description).to eq "This description could get really long"
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
                described_class.generate_from_hash(data: invalid_data)
              end.to raise_error(RuntimeError)
            end.not_to change { Sipity::Workflow.count }
          end.not_to change { Sipity::WorkflowAction.count }
        end.not_to change { Sipity::WorkflowState.count }
      end

      it 'will not amend when new data is invalid' do
        described_class.generate_from_json_file(path: path)
        expect do
          expect do
            expect do
              expect do
                described_class.generate_from_hash(data: invalid_data)
              end.to raise_error(RuntimeError)
            end.not_to change { Sipity::Workflow.count }
          end.not_to change { Sipity::WorkflowAction.count }
        end.not_to change { Sipity::WorkflowState.count }
      end
    end
  end
end
