require "spec_helper"

RSpec.describe CurationConcerns::Workflow::WorkflowImporter do
  let(:path) { double(read: json) }
  let(:json) do
    doc = <<-HERE
    {
      "workflows": [
        {
          "name": "ulra_submission",
          "label": "This is the label",
          "description": "This description could get really long",
          "allows_access_grant": true,
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
      expect(CurationConcerns::Workflow::WorkflowPermissionsGenerator).to receive(:call).and_call_original
      expect(CurationConcerns::Workflow::SipityActionsGenerator).to receive(:call).and_call_original
      result = nil
      expect do
        result = described_class.generate_from_json_file(path: path)
      end.to change { Sipity::Workflow.count }.by(1)
      expect(result).to match_array(kind_of(Sipity::Workflow))
      first_workflow = result.first
      expect(first_workflow.label).to eq "This is the label"
      expect(first_workflow.description).to eq "This description could get really long"
      expect(first_workflow.allows_access_grant?).to be true
    end
  end
end
