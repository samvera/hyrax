require "spec_helper"

RSpec.describe CurationConcerns::Workflow::WorkflowImporter do
  let(:path) { double(read: json) }
  let(:json) do
    doc = <<-HERE
    {
      "work_types": [
        {
          "name": "ulra_submission",
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

  it 'exposes .generate_from_json_file as a convenience method' do
    expect_any_instance_of(described_class).to receive(:call)
    described_class.generate_from_json_file(path: path, validator: validator)
  end

  it 'validates the data against the schema' do
    subject
    expect(validator).to have_received(:call).with(data: subject.send(:data), schema: subject.send(:schema))
  end

  context '.generate_from_json_file' do
    let(:path) { Rails.root.join('config/workflows/generic_work_workflow.json').to_s }

    it 'will load the file and parse as JSON' do
      expect_any_instance_of(described_class).to receive(:call)
      described_class.generate_from_json_file(path: path)
    end
  end

  context 'data generation' do
    it 'creates the requisite data' do
      # expect(CurationConcerns::Workflow::EmailNotificationGenerator).to receive(:call).and_call_original.exactly(3).times
      expect(CurationConcerns::Workflow::WorkflowPermissionsGenerator).to receive(:call)
      expect(CurationConcerns::Workflow::SipityActionsGenerator).to receive(:call).and_call_original
      expect do
        described_class.generate_from_json_file(path: path)
      end.to change { Sipity::Workflow.count }.by(1)
    end
  end
end
